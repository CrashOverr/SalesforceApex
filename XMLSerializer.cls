/**************************************************************************************************************
* @desarrollado por Vass
* @autor            Alejandro Gómez
* @projecto         Comfandi
* @descripcion      Clase que parsea la respuesta del servicio soap, de xml a json, para las clases 
					ServiceInvoiceCreate y ServiceInvoiceStatusBatch
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            No.   Fecha         Autor                        Descripcion
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            1.0   03-12-2020   Alejandro Gómez (AG)          Creacion Clase.
**************************************************************************************************************/
public class XMLSerializer{
    private boolean serializeNulls = true;  							// Serializa los nodos XML incluso si el contenido es nulo
    private string rootElement;              							// Elemento raíz para envolver la cadena serializada.
    private Set<string> deSerializeAsArrayNodes = new Set<string>();	// Colección de nombres de nodos para deserializar como matriz.
    /*
	@Descripcion: serializa el objeto pasado a la cadena XML
	@Parametro: objectToSerialize = Objeto Apex para serializar en XML
	@Retorno: Cadena XML
	*/
    public string serialize(object objectToSerialize){        
        object deSerialized = JSON.deserializeUntyped(JSON.serialize(objectToSerialize));               
        return !string.isEmpty(rootElement) ? Wrap(rootElement,serialize((Map<string,object>)deSerialized)) : serialize((Map<string,object>)deSerialized);     
    }
	/*
	@Descripcion: serializa el objeto en una cadena XML.
	@Parametro: objectToSerialize = Objeto Apex para serializar en XML
	@Parametro: suppressApexObjectNulls = si es verdadero, no serializará elementos vacíos en XML.
	@Parametro: Nombre del elemento raíz con el que envolver la cadena serializada.
	@Retorno: Cadena XML
	*/
    public string serialize(object objectToSerialize,boolean suppressApexObjectNulls,string addRootElementName){
        this.serializeNulls = !suppressApexObjectNulls;
        this.rootElement = addRootElementName;
        return serialize(objectToSerialize);
    }
	/*
	@Descripcion: convierte una cadena JSON en una cadena XML.
	@Parametro: jsonString = jsonString
	@Retorno: Cadena XML
	*/
    public string jsonToXML(string jsonString){
        object deSerialized = JSON.deserializeUntyped(jsonString);               
        return !string.isEmpty(rootElement) ? Wrap(rootElement,serialize((Map<string,object>)deSerialized)) : serialize((Map<string,object>)deSerialized);
    }
	/*
	@Descripcion: convierte una cadena JSON en una cadena XML.
	@Parametro: jsonString = jsonString
	@Parametro: suppressNulls = ignora los elementos Json vacíos, si es verdadero
	@Retorno: Cadena XML
	*/
    public string jsonToXML(string jsonString,boolean suppressNulls){
        this.serializeNulls = !suppressNulls;       
        return jsonToXML(jsonString);
    }
	/*
	@Descripcion: desSerializa el xml en el objeto de apextype
	@Parametro: xmlString = Cadena xml para desserializar
	@Parametro: apexType = tipo de objeto para desSerializar
	@Retorno: objeto de tipo apexType
	*/
    public object deSerialize(string xmlString, System.Type apexType){   
        string json = XMLToJson(xmlString); 
        return System.JSON.deserialize(json,apexType);  		
    }
	/*
	@Descripcion: desSerializa el xml en el objeto del tipo pasado
	@Parametro: xmlString = Cadena xml para desserializar
	@Parametro: apexType = tipo de objeto para desSerializar
	@Parametro: deSerializeNodesAsArray = colección de nombres de nodos para deserializar como matriz (incluso si la representación xml no es una matriz)
	@Retorno: objeto de tipo apexType
	*/
    public object deSerialize(string xmlString, System.Type apexType,Set<String> deSerializeNodesAsArray){   
        this.deSerializeAsArrayNodes = toLower(deSerializeNodesAsArray);
        return deSerialize(xmlString,apexType);		
    }    
	/*
	@Descripcion: desSerializa la cadena xml en una colección de tipos de datos primitivos.
	@Parametro: xmlString = Cadena xml para desserializar
	@Retorno: colección de tipos de datos primitivos
	*/ 
    public object deSerializeUnTyped(string xmlString){  
        return xmlToUnTyped(xmlString);  		
    }
	/*
	@Descripcion: desSerializa la cadena xml en una colección de tipos de datos primitivos.
	@Parametro: xmlString = Cadena xml para desserializar
	@Parametro: deSerializeNodesAsArray = colección de nombres de nodos para deserializar como matriz (incluso si la representación xml no es una matriz)
	@Retorno: colección de tipos de datos primitivos
	*/
    public object deSerializeUnTyped(string xmlString,Set<string> deSerializeNodesAsArray){  
        this.deSerializeAsArrayNodes = toLower(deSerializeNodesAsArray);
        return xmlToUnTyped(xmlString);  		
    }
	/*
	@Descripcion: convierte una cadena XML en una cadena json
	@Parametro: xmlString = Cadena XML para convertir
	@Retorno: Cadena JSON
	*/
    public  string XMLToJSON(string xmlString){
        return System.JSON.serialize(XMLToUnTyped(xmlString));
    } 
	/*
	@Descripcion: convierte una cadena XML en una cadena json
	@Parametro: xmlString = Cadena XML para convertir
	@Parametro: deSerializeNodesAsArray = colección de nombres de nodos para deserializar como matriz (incluso si la representación xml no es una matriz)
	@Retorno: Cadena JSON
	*/
    public  string xmlToJSON(string xmlString,Set<string> deSerializeNodesAsArray){  
        this.deSerializeAsArrayNodes = toLower(deSerializeNodesAsArray);
        return System.JSON.serialize(XMLToUnTyped(xmlString));
    }   
	/*
	@Descripcion: restablece las opciones de serialización y deserialización a las predeterminadas
	*/
    public void resetDefaults(){
        this.serializeNulls = true;
        this.rootElement = null;
        this.deSerializeAsArrayNodes.clear();
    }
	// Helpers
    /*
	@Descripcion: método serializar
	@Parametro: objectMap = Mapa de String y objetos
	@Retorno: Cadena XML
	*/
    private string serialize(Map<string,object> objectMap){
        string xmlString = '';    
        for(string key:objectMap.keySet()){  
            object o = objectMap.get(key);
            if(o == null) { if(this.SerializeNulls)     xmlString += wrap(key,null); }                       
            else if(o InstanceOf List<object> )         xmlString += serialize((List<object>) o,key);
            else if(o InstanceOf Map<string,object> )   xmlString += wrap(key,serialize((Map<string,object>) o));
            else                                        xmlString += wrap(key,string.valueOf(o));                               
        }
        return xmlString;
    }
	/*
	@Descripcion: método serializar
	@Parametro: objectList = Lista de objetos
	@Parametro: clave = clave para envolver todos los elementos de la lista con
	@Retorno: Cadena XML
	*/
    private string serialize(List<object> objectList, string key){
        string xmlString = '';      
        for(object o:objectList){    
            if (o InstanceOf string)				xmlString += wrap(key,string.valueOf(o)); 	
            else if(o InstanceOf List<object> )  	xmlString += wrap(key,serialize((List<object>) o, key));
            else                            		xmlString += wrap(key,serialize((Map<string,object>) o));                
        }     
        return xmlString;
    }
	/*
	@Descripcion: Envuelve el valor con el elemento xml clave
	@Parametro: clave = nombre de nodo Xml
	@Parametro: valor = valor del nodo xml
	@Retorno: Cadena XML
	*/
    private string wrap(string key, string value){
        return (string.isNotBlank(value) || serializeNulls) ? ('<' + key + '>' + (string.isBlank(value)?'':value) + '</' + key + '>') : value;
    }
	/*
	@Descripcion: desSerializa la cadena xml en una colección de tipos de datos primitivos.
	@Parametro: xmlString = Cadena xml para desserializar
	@Parametro: deSerializeNodesAsArray = colección de nombres de nodos para deserializar como matriz (incluso si la representación xml no es una matriz)
	@Retorno: colección de tipos de datos primitivos
	*/  
    private  Map<string,object> XMLToUnTyped(string xmlString){
        xmldom xd = new xmldom(xmlString);
        xmldom.Element document = xd.ownerDocument();
        return (Map<string,object>)parseNode(document);
    }  
	/*
	@Descripcion: analiza un nodo XML
	@Parametro: e = nodo xml (de tipo xmldom.Element)
	@Retorno: objeto
	*/
    private object parseNode(xmldom.Element e){
        if(e.childNodes.size()>0) return complexNodeToMap(e); 
        else  return e.nodeValue;  
    }
	/*
	@Descripcion: Convierte un nodo xml complejo en una colección de tipos primitivos.
	@Parametro: e = nodo xml (de tipo xmldom.Element)
	@Retorno: Representación cartográfica del nodo.
	*/
    private Map<string,object> complexNodeToMap(xmldom.Element e){       
        Map<string,object> cNodeMap = new Map<string,object>();
        for(xmldom.Element cNode : e.childNodes){                 
            if(cNodeMap.containsKey(cNode.nodeName)){                    
                object o = cNodeMap.get(cNode.nodeName);                    
                if(o InstanceOf List<object>) ((List<object>) o).add(parseNode(cNode));
                else cNodeMap.put(cNode.nodeName,new List<object>{o,parseNode(cNode)});                    
            }
            else cNodeMap.put(cNode.nodeName, deSerializeAsArrayNodes.contains(cNode.nodeName.toLowerCase())? new List<object>{parseNode(cNode)} : parseNode(cNode));
        }
        return cNodeMap;
    } 
	/*
	@Descripcion: convierte todos los elementos del conjunto a minúsculas
	@Parametro: stringSet = Conjunto de cadenas para convertir a minúsculas.
	@Retorno: conjunto de cadenas convertido.
	*/
    private Set<string> toLower(Set<string> stringSet){
        Set<string> lowerStringSet = new Set<string>();
        for(string s:stringSet) lowerStringSet.add(s.toLowerCase());
        return lowerStringSet;
    }
}
