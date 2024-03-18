<?php 

/**
 * This class defined a set of handy functions for connecting to Xtrapower's database.
 * Should be used internally
 */
final class DBConnExtension
{
    /**
     * Connect to Xtrapower's database
     */
    public static function xtra(string $host, int $port, string $dbname): DBConn
    { return DBConn::pg($host, $port, $dbname, "postgres", "xtra!@#$%"); }

    /**
     * Connect to Xtrapower's auth database
     */
    public static function xtraAuth(): DBConn { return self::xtra("auth.xtradns.com", 5432, "xtra"); }
    
    /**
     * Connect to Xtrapower's database with a secret key
     */
    public static function xtraWithKey(string $key): DBConn
    {
        $conn = self::xtraAuth();
        $sql = "
            SELECT db_server AS host, db_port AS port, db_name as dbname
            FROM ar_authentication
            WHERE upper(secretphrase) = upper(:secretphrase);
        ";
        $opResult = $conn->exec($sql, ["secretphrase" => $key]);
        if ($opResult->getRowCount() === 1) {
            $row = $opResult->getDataSet()[0];
            return self::xtra($row["host"], $row["port"], $row["dbname"]);
        } else {
            throw new \Exception("No database found with given key");
        }
    }
}