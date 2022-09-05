/**************************************************************************************************************
* @desarrollado por Vass
* @autor            Alejandro Gómez
* @projecto         Comfandi
* @descripcion      Clase de utilidad del dom para uso de la clase XMLSerializer
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            No.   Fecha         Autor                        Descripcion
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            1.0   03-12-2020   Alejandro Gómez (AG)          Creacion Clase.
**************************************************************************************************************/
public class XMLDom {
    // Constructor 
    public XMLDom(string str) { parseFromString(str); } 
    public XMLDom(          ) { }
    public void parseFromString(string str) {   
        XmlStreamReader reader = new XmlStreamReader(str);
        reader.setCoalescing(true);
        parseXmlReader (root , reader); 
    }
    // asistencia de depuración
    public void dumpAll() { root.dumpAll(); } 
    public void dumpList(Element[] l) { for(Element e:l) e.dump(); }
    integer count = 0 ; 
    // dado un nodo principal y un lector de flujo, completa el árbol de abajo aquí (recursivo)
    void parseXmlReader( Element parent, XmlStreamReader reader ) {
        try {
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    Element child = new Element( reader.getLocalName() );
                    // agrega todos los atributos de este elemento
                    for (integer i=0; i<reader.getAttributeCount(); i++) { 
                        child.attributes.put(   reader.getAttributeLocalName(i), reader.getAttributeValueAt(i) );
                    }
                    // agregar información de espacio de nombres a cada nodo / elemento (por ahora almacenar en el mapa de atributos)
                    for (integer j=0; j<reader.getNamespaceCount(); j++) { 
                        string prefix = 'xmlns'; 
                        if (reader.getnamespaceprefix(j)!=null)
                            prefix = reader.getnamespaceprefix(j); 
                        child.attributes.put( prefix , reader.getnamespaceuriat(j) );
                    } 
                    parent.appendChild(child); // agrega el nuevo elemento al padre actual
                    if (child.nodeName=='item') { count++; }
                    if (child.nodeName=='entry') { count++; }
                    if (count > 10) { return; } // Evita un error en el lector xmlstream
                    if (reader.hasNext()) reader.next();
                    else return;
                    parseXmlReader(child, reader) ; // recurse
                } else if (reader.getEventType() == XmlTag.END_ELEMENT) {   
                    reader.next();
                    return; 
                } else if (reader.getEventType() == XmlTag.CHARACTERS) {
                    if ( ! reader.isWhitespace()) { 
                        parent.nodeValue += reader.getText(); // agregar texto al elemento actual
                    }
                    reader.next();
                }
                else { 
                    reader.next(); 
                }   
            }
        } catch(Exception e) { // ParseError si obtenemos una respuesta truncada, permítala
            system.debug('caught '+e);
            parent.dumpAll();
        }
    }   
    
    // acceder a los nodos en el árbol usando estos captadores
    public List<Element> getElementsByTagName(string nam) {
        return root.getElementsByTagName(nam); 
    }
    public Element       getElementByTagName(string nam) {
        List<Element> r = root.getElementsByTagName(nam);
        if (r.size() == 0) return null; 
        return r[0];
    }
    // funciones dom de utilidad
    public Element ownerDocument() { return root; }
    // todo en el dom se encuentra como childNodes bajo este elemento raíz
    public Element root = new Element('#document');
    public integer debug =0;
    // volcar el árbol de elementos
    public String toXmlString() { return root.toXmlString(); }
    public class Element {
        public Element(string n) {  nodeName = n; } 
        public Element() {  }
        
        public string getAttribute(string name) { 
            return attributes.get(name); 
        }
        public void appendChild(Element e) {
            e.ParentNode = this; 
            this.childNodes.add(e);     
        }
        public void removeChild(Element e) {
            Element p = e.parentNode;
            List<Element> kids = new List<Element> {};
                for( Element ee: e.parentNode.childNodes) {
                    if (ee != e) 
                        kids.add(ee); 
                }
            p.childNodes = kids;
        }
        // atraviesa debajo de este nodo, devolviendo todos los nodos coincidentes por nombre
        public List<Element> getElementsByTagName(string nam) { 
            List<Element> ret = new List<Element>{};
                if (nam == this.nodeName) ret.add(this);
            for (Element c: this.childNodes) { 
                ret.addAll( c.getElementsByTagName(nam) ); // decend tree
            }
            return ret;
        }
        // como arriba, pero solo devuelve el primero que coincide
        public Element       getElementByTagName(string nam) {
            List<Element> r =   getElementsByTagName(nam);
            if (r.size() == 0) return null; 
            return r[0];
        }
        // el primero que coincide, solo devuelve el nodeValue
        public string getValue(string nam) {
            Element e = getElementByTagName(nam); 
            return (e==null?null:e.nodeValue); 
        }
        // algo de ayuda para depurar
        public void dump() { dump('');}
        public void dump(string pre) { // solo nodo actual
            
            system.debug( pre + ' ' +this.nodeName + '->' + this.nodeValue + ' ' + this.attributes );  
        }
        public void dumpAll() { dumpAll('');    }
        public void dumpAll(string pre) { // nodo y todos los hijos
            
            system.debug( pre + this.nodeName + '->' + this.nodeValue + ' ' + this.attributes );  
            for (Element c: this.childNodes) { 
                c.dumpAll(pre+'   '); 
            }
        }
        public string toXmlString() {
            string ret = '<' + this.nodeName + ' ';
            for (  string a : attributes.keySet() ) {
                ret += a + '=\'' + attributes.get(a) + '\' ' ;
            }
            ret += '>';
            if (nodeValue == '' ) ret += '\n';
            for (Element c: this.childNodes) {  
                ret += c.toXmlString() ;
            }   
            if (nodeValue != '' ) 
                ret += nodeValue;
            return ret + '</' + this.nodeName + '>\n'; 
        }
        public List<Element> getElementsByPath(string path) {   
            List<Element> ret = new List<Element>{};
                if ( Pattern.matches(path, this.path()) ) ret.add(this);
            for (Element c: this.childNodes) ret.addAll( c.getElementsByPath(path) );
            return ret;
        }    
        public string path() { 
            Element t = this;
            string ret = t.nodeName; 
            while (t.parentNode != null && t.parentNode.nodeName != '#document') { 
                t = t.parentNode;
                ret = t.nodeName + '/'+ret;
            }
            return '/'+ret;
        }
        // métodos de utilidad
        public Element firstChild() { 
            if ( this.childNodes.size() == 0 ) return null; 
            return this.childNodes[0]; 
        }
        public string textContent() { return this.nodeValue; } 
        public boolean hasChildNodes() { return childNodes.size()>0; }
        public boolean isEqualNode(Element comp) { return this.nodeName == comp.nodeName; } 
        public Element cloneNode() { return this.clone(); } 
        public boolean hasAttributes() { return ! attributes.isEmpty(); } 
        public boolean isSameNode(Element comp) { return this === comp; }       
        public Element ownerDocument() { 
            Element ret = this; 
            while( ret.parentNode != null) { ret = ret.parentNode; }            
            return ret; 
        } 
        // propiedades
        public Element parentNode = null; // solo la raíz tiene un padre nulo
        public string nodeName = ''; 
        public string nodeValue = ''; 
        public List<Element> childNodes = new List<Element>();
        public map<String,String> attributes = new map<String,String>();
    }
}
