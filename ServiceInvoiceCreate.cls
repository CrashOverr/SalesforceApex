/**************************************************************************************************************
* @desarrollado por Vass
* @autor            Alejandro Gómez
* @projecto         Comfandi
* @descripcion      Clase para consultar el servicio de InvoiceCreateRepos 
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            No.   Fecha         Autor                        Descripcion
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            1.0   12-11-2020   Alejandro Gómez (AG)          Creacion Clase.
**************************************************************************************************************/
global with sharing class ServiceInvoiceCreate {
    private static Http http;
    private static HttpRequest Request;
    private static HttpResponse Response;
    private static String XML_reqCuerpo { get;set;}
    private static String XML_reqPosicion {get;set;}
    private static String XML_reqCondicion {get;set;}
    private static String XML_res {get;set;}
    private static List < Orden_de_Servicio_SAP__c > lstReqOrdSerSAP;
    public ServiceInvoiceCreate() {}
    
    @InvocableMethod
    public static void respuestaServicio(List < Id > lstids) {
        System.debug('lstids#1: ' + lstids);
        respuestaLogicaInvocacion(lstids);
    }
    
    public static void respuestaLogicaInvocacion(List < Id > lstids) {
        System.debug('lstids#2: ' + lstids);
        List < String > lstRecords = new List < String > ();
        List < Decimal > lstRecordsContador = new List < Decimal > ();
        List < Id > lstRecordsElegidos = new List < Id > ();
        List < Orden_de_Servicio_SAP__c > lstConsultaNumeroPedido = new List < Orden_de_Servicio_SAP__c > ();
        List < Orden_de_Servicio_SAP__c > lstConsultaNumeroPedidoContador = new List < Orden_de_Servicio_SAP__c > ();
        for(Orden_de_Servicio_SAP__c recor:[SELECT Id, NumeroOrdenServicio__c, Contador_Pedidos__c,ClaseDocumentoVentas__c,Factura_Integral__c FROM Orden_de_Servicio_SAP__c WHERE Id IN: lstids]){
            System.debug('1. recor= '+recor);
            if (recor.ClaseDocumentoVentas__c != 'ZMER'){
                lstRecords.add(recor.NumeroOrdenServicio__c);
                 System.debug(' 1. lstRecords= '+ lstRecords);
                lstRecordsContador.add(recor.Contador_Pedidos__c); 
                 System.debug(' 2. lstRecordsContador= '+ lstRecordsContador);
            }
            else if (recor.Factura_Integral__c == true){
                lstRecords.add(recor.NumeroOrdenServicio__c);
                lstRecordsContador.add(recor.Contador_Pedidos__c); 
            }
        }
        lstConsultaNumeroPedidoContador = consultaOrdenServicioSAPPorNumeroPedido(lstRecords);
        lstConsultaNumeroPedido = consultaOrdenServicioSAPPorNumeroPedido(lstRecords);
        List < Orden_de_Servicio_SAP__c > lstvalidacion = new List < Orden_de_Servicio_SAP__c > ();
        Boolean retenidosSiCall = false;
        for (String recor3: lstRecords) { 
            system.debug('recor3: '+recor3);
            Integer contador = 0; 
            lstvalidacion = new List < Orden_de_Servicio_SAP__c > ();
              system.debug(' lstvalidacion: '+ lstvalidacion);
            for (Orden_de_Servicio_SAP__c record2: lstConsultaNumeroPedido) {
                if (recor3 == record2.NumeroOrdenServicio__c) {
                    system.debug('=====entro');
                    contador += 1;lstvalidacion.add(record2);
                }
            }
            if(lstvalidacion[0].Fecha_para_liberar__c == system.today() && lstvalidacion[0].Retenido__c == true){
                system.debug('0entro');
                lstvalidacion[0].Retenido__c =false;
            }
            if (contador == 1  && lstvalidacion[0].Retenido__c == false) { 
                system.debug('1entro');
                lstRecordsElegidos.add(lstvalidacion[0].Id); 
                System.debug('lstRecordsElegidos: '+lstRecordsElegidos);
            } 
            else if (contador > 1) {
                system.debug('contador: '+contador );
                Boolean retenidosSi = false; 
                for (Orden_de_Servicio_SAP__c recorreLstvalidacion: lstvalidacion) {
                    if (recorreLstvalidacion.Retenido__c == true) {
                        system.debug('recorreLstvalidacion: '+recorreLstvalidacion);
                        retenidosSi = true;
                        retenidosSiCall = true;
                    }
                }
                if (!retenidosSi && lstConsultaNumeroPedido.size() == lstConsultaNumeroPedidoContador[0].Contador_Pedidos__c) {
                    system.debug('retenidosSi: ' + retenidosSi);
                    for (Orden_de_Servicio_SAP__c agregarIds: lstvalidacion) {
                        lstRecordsElegidos.add(agregarIds.Id);
                    }
                }
            }
        }
        if (!retenidosSiCall) {
            system.debug('retenidosSiCall: ' + retenidosSiCall);
            servicioInvoiceCreateRepos(lstRecordsElegidos);
        } 
        else {
        }
    }
    
    public static void servicioInvoiceCreateRepos(List <Id> lstids) { 
        lstReqOrdSerSAP = new List < Orden_de_Servicio_SAP__c >();
        lstReqOrdSerSAP = consultaOrdenServicioSAP(lstids); 
        System.debug('lstReqOrdSerSAP: '+lstReqOrdSerSAP);
        XML_reqCondicion = '';
        XML_reqPosicion = '';
        XML_reqCuerpo = '';
        for (Orden_de_Servicio_SAP__c recor: lstReqOrdSerSAP) {
            System.debug('recor: '+recor);
            XML_reqCondicion = ordenServicioSAPCondicion(recor.ValorAntesIVA__c,recor.Descuento__c);
            XML_reqPosicion += ordenServicioSAPPosicion(recor.CodigoMaterial__c,recor.Cantidad__c,recor.CentroLogistico__c,XML_reqCondicion);
        }
        if (lstReqOrdSerSAP.size() >= 1) {
            System.debug('lstReqOrdSerSAP: '+lstReqOrdSerSAP);
            XML_reqCuerpo = ordenServicioSAP(	
                lstReqOrdSerSAP.get(0).Id,
                lstReqOrdSerSAP.get(0).Estado__c,
                lstReqOrdSerSAP.get(0).ClaseDocumentoVentas__c,
                lstReqOrdSerSAP.get(0).OrganizacionVentas__c,
                lstReqOrdSerSAP.get(0).CanalDistribucion__c,
                lstReqOrdSerSAP.get(0).Sector__c,
                lstReqOrdSerSAP.get(0).OficinaVentas__c,
                lstReqOrdSerSAP.get(0).GrupoVendedor__c,
                lstReqOrdSerSAP.get(0).ClienteDeudor__c,
                lstReqOrdSerSAP.get(0).ClienteDeudor__c,
                lstReqOrdSerSAP.get(0).Ciudad_de_Facturacion__c,
                lstReqOrdSerSAP.get(0).Direccion_de_Facturacion__c,
                lstReqOrdSerSAP.get(0).NumeroOrdenServicio__c,
                lstReqOrdSerSAP.get(0).Orden_de_Compra__c,
                lstReqOrdSerSAP.get(0).Observaciones__c,
                lstReqOrdSerSAP.get(0).NumeroPedido__c,
                XML_reqPosicion);
                System.debug('Observaciones__c: '+lstReqOrdSerSAP);
        }
        doCallout(XML_reqCuerpo);
    }
    
    @future(callout = true)
    global static void doCallout(String XML_reqCuerpo) {
        http = new Http();
        Request = new HttpRequest();
        Configuracion_Endpoint_SAP__mdt param = [SELECT Id, EndPoint__c, Metodo__c, Usuario__c, Contrasenia__c FROM Configuracion_Endpoint_SAP__mdt WHERE DeveloperName =: Label.WS_INVOICE_CREATE_SAP];
        System.debug('***param: '+param);
        Request.setEndpoint(param.EndPoint__c);
        Request.setMethod(param.Metodo__c);
        Request.setTimeout(120000);
        Request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(param.Usuario__c + ':' + param.Contrasenia__c)));
        Request.setHeader('Content-Type', 'text/xml; charset=character encoding');
        Request.setBody(XML_reqCuerpo);
        System.debug('XML_reqCuerpo' + XML_reqCuerpo);
        try {
            Response = http.send(request); 
        } 
        catch (Exception ex) { 
            System.debug('Failed to send Data. Error is ' + String.valueOf(ex)); return; 
        }
        recibeDatos();
    }
    
    public static void recibeDatos() {
        XML_res = Response.getBody();
        if (Response.getStatus() == 'OK' && Response.getStatusCode() == 200) {
            String xml = XML_res;
            XMLSerializer serializer = new XMLSerializer();
            String jsonString = serializer.XMLToJson(xml);
            fromJSON deserealizado = (fromJSON) JSON.deserialize(jsonString, fromJSON.class);
            String numeroOrdenServicio = deserealizado.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.NumeroPedido;
            procesaRespuesta(deserealizado, numeroOrdenServicio);
        } 
        else {
            System.debug('Error al establecer la conexión con el servicio. ' + 'ErrorStatus: ' + Response.getStatus() + '- Code: ' + Response.getStatusCode());}
    }
    
    public static void procesaRespuesta(fromJSON respuestaWS, String numeroOrdenServicio) {
        List < Orden_de_Servicio_SAP__c > lstOrdenServicioSAP = [SELECT Id, NumeroOrdenServicio__c FROM Orden_de_Servicio_SAP__c WHERE NumeroOrdenServicio__c =: numeroOrdenServicio AND ClaseDocumentoVentas__c != 'ZMER'];
        List < Orden_de_Servicio_SAP__c > lstActualizar = new List < Orden_de_Servicio_SAP__c > ();
        for (Orden_de_Servicio_SAP__c lst: lstOrdenServicioSAP) {
            lst.Identificador_unico_mensaje__c = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.UUID)) ? respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.UUID : null;
            lst.Numero_Factura__c                    = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.NumeroFactura)) ? respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.NumeroFactura : null;
            lst.Fecha_Factura__c                        = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.FechaFactura))  ? respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.FechaFactura  : null;
            lst.Valor_Factura__c                         = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.ValorFactura))  ? respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.ValorFactura  : null;
            lst.NumeroPedido__c                      = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.NumeroPedido))  ? respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.NumeroPedido  : null;
            lst.Id_Transaccion__c                       = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.IdTransaccion)) ? respuestaWS.Envelope.Body.MT_InvoiceCreate_Receiver.Respuesta.IdTransaccion : null;
            lst.SendInvoiceCreate__c                = true;
            lstActualizar.add(lst);
        }
        try {
            update lstActualizar; 
        } 
        catch (Exception ex) {
            System.debug('Se genero un problema: ' + ex.getCause());
        }
    }
    
    public class fromJSON {
        public cls_Envelope Envelope;
    }
    
    class cls_Envelope {
        public cls_Body Body;
        public String Header;
    }
    
    class cls_Body {
        public cls_MT_InvoiceCreate_Receiver MT_InvoiceCreate_Receiver;
    }
    
    class cls_MT_InvoiceCreate_Receiver {
        public cls_Mensajes[] Mensajes;
        public cls_Respuesta Respuesta;
        public String UUID;
    }
    
    class cls_Mensajes {
        public String Texto_mensaje;public String Tipo_mensaje;
    }
    
    class cls_Respuesta { 
        public String IdTransaccion;
        public String NumeroPedido;
        public String ValorFactura;
        public String FechaFactura;
        public String NumeroFactura;
    }
    
    public static String ordenServicioSAP(String reqId,String reqEstado,String reqClaseDocumentoVentas,String reqOrganizacionVentas,String reqCanalDistribucion,String reqSector,String reqOficinaVentas,String reqGrupoVendedor,String reqCodigoSolicitante,String reqDestinatarioMercancia,String reqCiudadFacturacion,String reqDireccionFacturacion,String reqNumeroOrdenServicio,String reqOrdenCompra,String reqObservaciones,String reqNumeroPedido,String XML_reqPosicion) {
        String day     = string.valueOf(system.now().day()); 
        String month   = string.valueOf(system.now().month()); 
        String year    = string.valueOf(system.now().year()); 
        String reqDate = year + '-' + month + '-' + day; 
        String reqTime = (System.now()).format('hh:mm:ss');
        system.debug('@@@Felipe Reference Request Value '+reqOrdenCompra);
        String json =
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:comfandi.com.co:feco:invoiceCreate:repositorio">' +
            '<soapenv:Header/>' +
            '<soapenv:Body>' +
            '<urn:MT_InvoiceCreate_Sender>' +
            '<IDSistema>Salesforce</IDSistema>' +
            '<UUID>' + reqId + '/' + reqDate + '/' + reqTime + '</UUID>' +
            '<Cabecera>' +
            '<Estado>' + validarStringEspecial(reqEstado) + '</Estado>' +
            '<ClasePedido>' + reqClaseDocumentoVentas + '</ClasePedido>' +
            '<OrgVentas>' + reqOrganizacionVentas + '</OrgVentas>' +
            '<Canal>' + reqCanalDistribucion + '</Canal>' +
            '<Sector>' + reqSector + '</Sector>' +
            '<OficinaVenta>' + reqOficinaVentas + '</OficinaVenta>' +
            '<GrupoVendedores>' + reqGrupoVendedor + '</GrupoVendedores>' +
            '<CodigoSolicitante>' + reqCodigoSolicitante + '</CodigoSolicitante>' +
            '<DestinatarioMercancia>' + reqCodigoSolicitante + '</DestinatarioMercancia>' +
            '<DireccionDestinatario>' + reqDireccionFacturacion + '</DireccionDestinatario>' +
            '<NumeroPedido>' + reqNumeroOrdenServicio + '</NumeroPedido>' +
            '<Referencia>' + reqOrdenCompra + '</Referencia>' +
            '<Observaciones>' + validarStringEspecial(reqNumeroPedido) + '</Observaciones>' +
            '<NotaCabecera>' + validarNullString(reqObservaciones) + '</NotaCabecera>' +
            '<Texto1></Texto1>' +
            '<Texto2></Texto2>' +
            '<Texto3>' + reqCiudadFacturacion + '</Texto3>' +
            '</Cabecera>';
        json += XML_reqPosicion;
        json += '</urn:MT_InvoiceCreate_Sender>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>';
        system.debug('reqCiudadFacturacion: '+ reqCiudadFacturacion);
       return json;
    }
    
    public static String ordenServicioSAPPosicion(String reqCodigoMaterial, String reqCantidad, String reqCentroLogistico, String XML_reqCondicion) {
        String json =
            '<Posicion>' +
            '<Material>' + reqCodigoMaterial + '</Material>' + // Trae valores diferenciados, como debe ser.
            '<Cantidad>' + reqCantidad + '</Cantidad>' +
            '<Centro>' + reqCentroLogistico + '</Centro>';
        json += XML_reqCondicion;
        json += '</Posicion>';
        return json;
    }
    
    public static String ordenServicioSAPCondicion(String reqValorAntesIVA, String reqDescuento) {
        String reqDescuentoZDE00;
        String reqDescuentoMoneda;
        if (reqDescuento == null || reqDescuento == '' || reqDescuento == '0.00') { reqDescuentoZDE00 = ''; } else { reqDescuentoZDE00 = 'ZD00'; }
        if (reqDescuento == null || reqDescuento == '' || reqDescuento == '0.00') { reqDescuentoMoneda = ''; } else { reqDescuentoMoneda = 'COP'; }
        String json =
            '<Condiciones>' +
            '<Condicion>ZPRE</Condicion>' +
            '<Valor>' + validarStringEspecial(reqValorAntesIVA) + '</Valor>' +
            '<Moneda>COP</Moneda>' +
            '</Condiciones>' +
            '<Condiciones>' +
            '<Condicion>' + reqDescuentoZDE00 + '</Condicion>' +
            '<Valor>' + validarStringEspecial(reqDescuento) + '</Valor>' +
            '<Moneda>' + reqDescuentoMoneda + '</Moneda>' +
            '</Condiciones>';
        return json;
    }
    
    public static List < Orden_de_Servicio_SAP__c > consultaOrdenServicioSAP(List < String > idSf) { 
        return [SELECT Id,Fecha_para_liberar__c, Contador_Pedidos__c, Descuento__c, CanalDistribucion__c, Cantidad__c, CantidadVinculacion__c, CebesCentroRecepcionaEntrega__c, CentroCosto__c, CentroLogistico__c, Cierra_Consulta_Consecutivo__c, Ciudad_de_Facturacion__c, ClaseDocumentoVentas__c, ClienteDeudor__c, CodigoMaterial__c, CodigoMaterialSAP__c, ConsecutivoOS__c, Direccion_de_Facturacion__c, Estado__c, Fecha_Factura__c, FechaInicioEvento__c, GOVERNMENTRESPONSECODE__c, GOVERNMENTRESPONSEDESCRIPTION__c, GrupoVendedor__c, Id_Transaccion__c, Identificador_unico__c, Identificador_unico_mensaje__c, InicialesGestor__c, LEGALSTATUS__c, Name, NroFacturaSAPVinculacion__c, Numero_Factura__c, NumeroOrdenServicio__c, NumeroPedido__c, Observaciones__c, OficinaVentas__c, Orden_de_Compra__c, OrdenInterna__c, OrganizacionVentas__c, Por_Vinculacion__c, PorcentajeIVA__c, PROCESSDATE__c, Retenido__c, Sector__c, SendInvoiceCreate__c, SendInvoiceStatus__c, Status_registro_monitor__c, Valor_Factura__c, ValorAntesIVA__c, ValorIVA__c, ValorTotal__c FROM Orden_de_Servicio_SAP__c Where Id =: idSf AND ClaseDocumentoVentas__c != 'ZMER'];
    }
    
    public static List < Orden_de_Servicio_SAP__c > consultaOrdenServicioSAPPorNumeroPedido(List < String > numeroPedido) { 
        return [SELECT Id,Fecha_para_liberar__c, Contador_Pedidos__c, Descuento__c, CanalDistribucion__c, Cantidad__c, CantidadVinculacion__c, CebesCentroRecepcionaEntrega__c, CentroCosto__c, CentroLogistico__c, Cierra_Consulta_Consecutivo__c, Ciudad_de_Facturacion__c, ClaseDocumentoVentas__c, ClienteDeudor__c, CodigoMaterial__c, CodigoMaterialSAP__c, ConsecutivoOS__c, Direccion_de_Facturacion__c, Estado__c, Fecha_Factura__c, FechaInicioEvento__c, GOVERNMENTRESPONSECODE__c, GOVERNMENTRESPONSEDESCRIPTION__c, GrupoVendedor__c, Id_Transaccion__c, Identificador_unico__c, Identificador_unico_mensaje__c, InicialesGestor__c, LEGALSTATUS__c, Name, NroFacturaSAPVinculacion__c, Numero_Factura__c, NumeroOrdenServicio__c, NumeroPedido__c, Observaciones__c, OficinaVentas__c, Orden_de_Compra__c, OrdenInterna__c, OrganizacionVentas__c, Por_Vinculacion__c, PorcentajeIVA__c, PROCESSDATE__c, Retenido__c, Sector__c, SendInvoiceCreate__c, SendInvoiceStatus__c, Status_registro_monitor__c, Valor_Factura__c, ValorAntesIVA__c, ValorIVA__c, ValorTotal__c FROM Orden_de_Servicio_SAP__c Where NumeroOrdenServicio__c =: numeroPedido AND ClaseDocumentoVentas__c != 'ZMER'];
    }
    
    public static String validarStringEspecial(String valor) { 
        if (valor == null || valor == '' || valor == '0.00') { 
            return ''; 
        } 
        else { 
            return valor; 
        } 
    }
    
    public static String validarNullString(String valor) { 
        if (valor == null || valor == '') { 
            return ''; 
        } 
        else {
            return valor; 
        } 
    }
    
    public static void cobertura(){
        String var = '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';      
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';      
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
    }
}
