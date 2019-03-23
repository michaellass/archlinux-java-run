import javafx.application.Application;
import javafx.stage.Stage;

public class TestJavaFX {
  public static void main (String[] args) {
    try {
      FXApplication testapp = new FXApplication();
    } catch (NoClassDefFoundError e) {
      System.exit(1);
    }
    System.exit(0);
  }
}

class FXApplication extends Application {
  @Override
  public void start(Stage primaryStage) throws Exception {}
}
