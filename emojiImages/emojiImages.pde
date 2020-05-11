
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import http.requests.*;

int SCALE = 200;
String toLoad = "";
String username = "username";
String api_key = "api_key";
String tag1 = "rating:safe";
String tag2 = "";

String fileName, id;
PImage template;
boolean complete = false;

volatile int pixel = 0; 
int imgLen;

BufferedWriter writer;

void setup() {
    size(200, 160);
    surface.setResizable(true);
    colorMode(HSB, width, height, 255);
    if (toLoad == "") {
      GetRequest get = new GetRequest("http://danbooru.donmai.us/posts.json?tags=" + tag1 + 
                                        (tag2 == "+" ?  "" : "") + tag2 +
                                        "&random=True&limit=1");
      get.addUser(username, api_key);
      JSONObject data;
      while (true) {
        get.send();
        data = parseJSONArray(get.getContent()).getJSONObject(0);
        if (data.getString("file_url") != null) {
          break;
        }
      }
      println("Url: " + data.getString("file_url"));
      println("Rating: " + data.getString("rating"));
      template = loadImage(data.getString("file_url"));
      id = Integer.toString(data.getInt("id"));
    } else {
      template = loadImage(toLoad);
      id = toLoad;
    }
    
    template.resize(SCALE, template.height/template.width * SCALE);
    imgLen = template.pixels.length;
    
  
    String pathToTxt = sketchPath("") + "/textout/" + id + ".txt";
    File f = new File(pathToTxt);
    
    if(f.exists()){
      f.delete();
      try {
        f.createNewFile();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    
    try {
      writer = new BufferedWriter( new FileWriter(pathToTxt, true));
    } catch (IOException e) {
    }
    surface.setSize(template.width, template.height);
    thread("picToEmoji");
}

void draw() {
  if (frameCount == 1) {
    surface.setSize(template.width, template.height);
  }
  if (!complete){
    image(template, 0, 0, width, height);
    float completion = (float)pixel / (float)imgLen;
    fill(0);
    rect(0, 0, width, height-height*completion);
  }
  if (imgLen == pixel) {
    complete = false;
    pixel = 0;
    if (toLoad == "") {
      setup();
    }
  }
  
}

void writeLine(String line) throws IOException {
  writer.write(line);
  writer.flush();
}

void picToEmoji() throws IOException {

    String out = "";
    int closestEmoji = 0;
    String[] nextLine;
    color nextColor;
    float thisDiff;
    float closestDiff;
    String[] lines = loadStrings("cleanedEmojiData.txt");
    PImage emojiImage = loadImage("emojiImage.png");
    PGraphics imgOut = createGraphics(template.width * 20, template.height * 20);
    imgOut.beginDraw();
    imgOut.fill(30);
    imgOut.strokeWeight(0);
    imgOut.rect(0, 0, imgOut.width, imgOut.height);
    
    while (pixel < imgLen) {
      
      if (pixel < template.width * template.height) {
          closestDiff = Float.MAX_VALUE;
          if (pixel == 0 || template.pixels[pixel-1] != template.pixels[pixel]) {
            for (int i = 0; i < lines.length; i++) {
              nextLine = split(lines[i], ",");
              nextColor = int(nextLine[1]);
              //thisDiff =  pow((red(nextColor)- red(template.pixels[pixel]))* 0.30, 2) + 
              //            pow((green(nextColor)-green(template.pixels[pixel]))* 0.59, 2) + 
              //            pow((blue(nextColor)-blue(template.pixels[pixel]))* 0.11, 2);
              thisDiff =  pow((float)(red(nextColor)- red(template.pixels[pixel])), 2) + 
                          pow((float)(green(nextColor)-green(template.pixels[pixel])), 2) + 
                          pow((float)(blue(nextColor)-blue(template.pixels[pixel])), 2);
              if (thisDiff < closestDiff) {
                closestDiff = thisDiff;
                closestEmoji = i;
              } 
            }
          }
        
        
        out += (lines[closestEmoji].split(",")[0] + "");
        imgOut.image(emojiImage.get(0, closestEmoji*20, 20, 20),
                    (pixel%template.width) *20, (pixel / template.width)*20);
        if ((pixel+1)%template.width == 0) {
          out += "\n";
        }
      } else {break;}
      pixel++;
    }  
    imgOut.endDraw();
    imgOut.save("imgOut/" + id + ".png");
    writeLine(out);
    writer.close();
}
