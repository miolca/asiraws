package sockets;


import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.net.Socket;
import java.util.Scanner;
/** ClientExample class, to create a simple example to connect two computer via a 
 * TCPIP connection
 *  */
public class ClientExample {
	
    /*Port 5005*/
    private final static int PORT =5005;

    private final static String SERVER = "44.201.65.160";
    
    public static void main(String[] args) {
    	boolean exit=false;//bandera para controlar ciclo del programa
        Socket socket;//Socket para la comunicacion cliente servidor        
        try {            
            System.out.println("Client -> Start");  
            socket = new Socket(SERVER, PORT);//open socket                
            //To read from the server      
            BufferedReader input = new BufferedReader( new InputStreamReader(socket.getInputStream()));                
            //to write to the server
            PrintStream output = new PrintStream(socket.getOutputStream());                
            //To read from the user (keyboard)           
            Scanner tec = new Scanner(System.in);            
            System.out.println("Client -> Write a sentence to send:");                
            String line = tec.nextLine();                
            //send the line to the server
            output.println(line); 
            //read the answer and print it
            String st = input.readLine();
            if( st != null ) System.out.println("Client -> received message: " + st );    
            System.out.println("Client -> End of the program");    
                 
            socket.close();
                                    
       } catch (IOException ex) {        
         System.err.println("Client -> " + ex.getMessage());   
       }
    }
    
}