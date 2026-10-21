import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

class CheckDatabase {
  static int checks = 0, errors = 0;
  static void checkQueries(Connection db, String text, String label) throws Exception {
    for (String block : text.split(";")) {
      String sql = block.replaceAll("(?m)^--.*$", "").trim();
      if (sql.isEmpty()) continue;
      checks++;
      try (Statement s = db.createStatement(); ResultSet rs = s.executeQuery(sql)) {
        int count = 0; while(rs.next()) count++;
        System.out.println("OK " + label + " requete " + checks + " : " + count + " lignes");
      } catch(SQLException e) { errors++; System.out.println("ECHEC " + label + " : " + e.getMessage() + " | " + sql); }
    }
  }
  public static void main(String[] args) throws Exception {
    Class.forName("org.hsqldb.jdbcDriver");
    String queries = Files.readString(Path.of(args[2]), StandardCharsets.UTF_8).replace("\uFEFF", "");
    try(Connection db = DriverManager.getConnection("jdbc:hsqldb:file:" + args[0].replace('\\','/'), "SA", "")) {
      DatabaseMetaData meta = db.getMetaData();
      List<String> tables = new ArrayList<>();
      try(ResultSet rs=meta.getTables(null, "PUBLIC", "%", new String[]{"TABLE"})) { while(rs.next()) tables.add(rs.getString("TABLE_NAME")); }
      if(tables.size()!=9) throw new Exception("Nombre de tables inattendu: " + tables);
      for(String table : tables) {
        try(Statement s=db.createStatement(); ResultSet rs=s.executeQuery("SELECT COUNT(*) FROM \""+table+"\"")) { rs.next(); System.out.println("TABLE " + table + " : " + rs.getInt(1) + " lignes"); checks++; }
        try(ResultSet keys=meta.getImportedKeys(null,"PUBLIC",table)) {
          while(keys.next()) {
            String sql="SELECT COUNT(*) FROM \""+table+"\" c LEFT JOIN \""+keys.getString("PKTABLE_NAME")+"\" p ON c.\""+keys.getString("FKCOLUMN_NAME")+"\"=p.\""+keys.getString("PKCOLUMN_NAME")+"\" WHERE c.\""+keys.getString("FKCOLUMN_NAME")+"\" IS NOT NULL AND p.\""+keys.getString("PKCOLUMN_NAME")+"\" IS NULL";
            try(Statement s=db.createStatement();ResultSet rs=s.executeQuery(sql)) {rs.next(); checks++; if(rs.getInt(1)!=0){errors++; System.out.println("ECHEC relation de "+table);} }
          }
        }
      }
      checkQueries(db,queries,"donnees originales");
    }
    try(Connection db=DriverManager.getConnection("jdbc:hsqldb:mem:verification_schema","SA","")) {
      String schema=Files.readString(Path.of(args[1]),StandardCharsets.UTF_8).replace("\uFEFF","");
      for(String sql:schema.split(";")) if(!sql.trim().isEmpty()) {try(Statement s=db.createStatement()){s.execute(sql);checks++;}}
      checkQueries(db,queries,"schema reconstruit");
    }
    System.out.println(checks + " controles, " + errors + " erreurs.");
    if(errors>0) System.exit(1);
  }
}
