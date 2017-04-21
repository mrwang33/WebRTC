import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.websocket.OnClose;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;


@ServerEndpoint("/games")
public class Server {
	static List<Session> list =new ArrayList<Session>();
	@OnOpen
	public void open(Session session){
		System.out.println(session.getId()+ "open");
		list.add(session);
	}
	@OnMessage
	public void OnMessage(String message, Session session){
		System.out.println(session.getId()+":"+message);
			if(list.size()>1){
			for (int i = 0; i < list.size(); i++) {
				if(!list.get(i).getId().equals(session.getId())){
					try {
						list.get(i).getBasicRemote().sendText(message);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
			}
		}
	}
	@OnClose
	public void close(Session session){
		list.remove(session);
	}
}
