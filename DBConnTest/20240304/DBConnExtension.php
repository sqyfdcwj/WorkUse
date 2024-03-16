<?php 

require_once 'DBConn.php';

/**
 * This class has defined serveral handy functions for connecting to Xtrapower's database.
 * Should be used internally
 */
class DBConnExtension
{
    public static function xtra(string $host, int $port, string $dbname): DBConn
    { return DBConn::pg($host, $port, $dbname, "postgres", "xtra!@#$%"); }

    public static function xtraAuth(): DBConn { return self::xtra("auth.xtradns.com", 5432, "xtra"); }
    
    public static function xtraWithKey(string $key): DBConn
    {
        $conn = self::xtraAuth();
        $sql = "
            SELECT db_server AS host, db_port AS port, db_name as dbname,
                coalesce(NULLIF(db_login_name, ''), 'postgres') AS user,
                coalesce(NULLIF(db_login_password, ''), 'xtra!@#$%') AS password
            FROM ar_authentication
            WHERE upper(secretphrase) = upper(:secretphrase);
        ";
        $opResult = $conn->exec($sql, ["secretphrase" => $key]);
        if ($opResult->getRowCount() === 1) {
            $row = $opResult->getDataSet()[0];
            return DBConn::pg($row["host"], $row["port"], $row["dbname"], $row["user"], $row["password"]);
        } else {
            throw new \Exception("No database found with given key");
        }
    }
}