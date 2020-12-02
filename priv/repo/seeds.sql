-- MySQL dump 10.13  Distrib 8.0.22, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: hal_test
-- ------------------------------------------------------
-- Server version	5.7.24

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

USE `hal_test`;

--
-- Table structure for table `addresses`
--

DROP TABLE IF EXISTS `addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`addresses` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned DEFAULT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `company_name` varchar(50) DEFAULT NULL,
  `address1` varchar(60) DEFAULT NULL,
  `address2` varchar(60) DEFAULT NULL,
  `city` varchar(40) DEFAULT NULL,
  `state` varchar(40) DEFAULT NULL,
  `zip` varchar(20) DEFAULT NULL,
  `country` varchar(2) DEFAULT NULL,
  `auth_shipping_address_id` varchar(30) DEFAULT NULL,
  `beans_id` bigint(20) unsigned DEFAULT NULL,
  `beansbooks_id` bigint(20) unsigned DEFAULT NULL,
  `beansbooks_shipping_id` bigint(20) unsigned DEFAULT NULL,
  `removed` tinyint(1) NOT NULL DEFAULT '0',
  `shipping` tinyint(1) NOT NULL DEFAULT '0',
  `easy_post_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IDX_6FCA7516A76ED395` (`user_id`),
  FULLTEXT KEY `addresses_search` (`first_name`,`last_name`,`company_name`,`address1`,`address2`,`city`,`state`,`zip`,`country`)
) ENGINE=InnoDB AUTO_INCREMENT=1000003 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `addresses`
--

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `hal_test`.`addresses` DISABLE KEYS */;
INSERT INTO `addresses` VALUES (1,NULL,'System76','RMA','System76, Inc.','1600 Champa St.','Suite 360','Denver','CO','80202','US',NULL,NULL,NULL,NULL,0,0,NULL),(1000001,NULL,'System76','RMA','System76, Inc.','4240 Carson St.','Suite 101','Denver','CO','80239','US',NULL,NULL,1,NULL,0,0,NULL),(1000002,NULL,'Micro','Center','Micro Center','8000 E Quincy Ave.',NULL,'Denver','CO','80237','US',NULL,NULL,NULL,NULL,0,0,NULL);
/*!40000 ALTER TABLE `hal_test`.`addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `components`
--

DROP TABLE IF EXISTS `components`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`components` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(254) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `unit` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `sku` varchar(30) DEFAULT NULL,
  `cost` double DEFAULT NULL,
  `count` smallint(6) DEFAULT NULL,
  `display_count` smallint(6) DEFAULT NULL,
  `supplier_id` smallint(6) DEFAULT NULL,
  `shipping_weight` double DEFAULT NULL,
  `shipping_depth` double DEFAULT NULL,
  `shipping_height` double DEFAULT NULL,
  `shipping_width` double DEFAULT NULL,
  `shipping_handling_fee` double unsigned DEFAULT NULL,
  `shipping_insurance` enum('always','never','auto') NOT NULL DEFAULT 'auto',
  `shipping_confirmation` enum('always','never') NOT NULL DEFAULT 'always',
  `removed` tinyint(1) NOT NULL DEFAULT '0',
  `assembly_message` text,
  `v` smallint(6) NOT NULL DEFAULT '0',
  `refundable` tinyint(1) NOT NULL DEFAULT '1',
  `placeholder` tinyint(1) NOT NULL DEFAULT '0',
  `type` varchar(255) NOT NULL DEFAULT 'legacy',
  PRIMARY KEY (`id`),
  KEY `IDX_EE48F5FD2ADD6D8C` (`supplier_id`),
  FULLTEXT KEY `components_search` (`name`,`description`,`type`,`sku`)
) ENGINE=InnoDB AUTO_INCREMENT=1000093 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_configurations`
--

DROP TABLE IF EXISTS `inventory_configurations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_configurations` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `component_id` int(10) unsigned NOT NULL,
  `sku_id` bigint(20) unsigned NOT NULL,
  `quantity` int(11) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `inventory_configurations_component_id_sku_id_index` (`component_id`,`sku_id`),
  KEY `inventory_configurations_sku_id_fkey` (`sku_id`),
  CONSTRAINT `inventory_configurations_component_id_fkey` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`) ON DELETE CASCADE,
  CONSTRAINT `inventory_configurations_sku_id_fkey` FOREIGN KEY (`sku_id`) REFERENCES `inventory_skus` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=68 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_locations`
--

DROP TABLE IF EXISTS `inventory_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_locations` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) DEFAULT NULL,
  `area` enum('receiving','transit','storage','assembly','shipping','shipped') NOT NULL,
  `name` varchar(255) NOT NULL,
  `disabled` tinyint(1) DEFAULT '0',
  `removed` tinyint(1) DEFAULT '0',
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inventory_locations_uuid_index` (`uuid`),
  FULLTEXT KEY `inventory_locations_search` (`uuid`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1000076 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_manufacturers`
--

DROP TABLE IF EXISTS `inventory_manufacturers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_manufacturers` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `removed` tinyint(1) NOT NULL DEFAULT '0',
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  FULLTEXT KEY `inventory_manufacturers_search` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1000078 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_manufacturers`
--

LOCK TABLES `inventory_manufacturers` WRITE;
/*!40000 ALTER TABLE `hal_test`.`inventory_manufacturers` DISABLE KEYS */;
INSERT INTO `inventory_manufacturers` VALUES (1000001,'System76',0,'2020-10-08 19:30:25','2020-10-08 19:30:25'),(1000002,'nVidia',0,'2020-10-08 19:30:25','2020-10-08 19:30:25'),(1000003,'Crucial',0,'2020-10-08 19:30:25','2020-10-08 19:30:25');
/*!40000 ALTER TABLE `hal_test`.`inventory_manufacturers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_parts`
--

DROP TABLE IF EXISTS `inventory_parts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_parts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) DEFAULT NULL,
  `serial_number` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `location_id` bigint(20) unsigned NOT NULL,
  `purchase_order_line_id` bigint(20) unsigned NOT NULL,
  `assembly_build_id` bigint(20) unsigned DEFAULT NULL,
  `rma_description` varchar(255) DEFAULT NULL,
  `rma_purchase_order_id` bigint(20) unsigned DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `sku_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inventory_parts_uuid_index` (`uuid`),
  KEY `inventory_parts_current_location_id_fkey` (`location_id`),
  KEY `inventory_parts_purchase_order_line_id_fkey` (`purchase_order_line_id`),
  KEY `inventory_parts_assembly_build_id_fkey` (`assembly_build_id`),
  KEY `inventory_parts_rma_purchase_order_id_fkey` (`rma_purchase_order_id`),
  KEY `inventory_parts_sku_id_fkey` (`sku_id`),
  FULLTEXT KEY `inventory_parts_search` (`uuid`,`serial_number`,`rma_description`),
  CONSTRAINT `inventory_parts_assembly_build_id_fkey` FOREIGN KEY (`assembly_build_id`) REFERENCES `assembly_builds` (`id`) ON DELETE SET NULL,
  CONSTRAINT `inventory_parts_current_location_id_fkey` FOREIGN KEY (`location_id`) REFERENCES `inventory_locations` (`id`),
  CONSTRAINT `inventory_parts_purchase_order_line_id_fkey` FOREIGN KEY (`purchase_order_line_id`) REFERENCES `inventory_purchase_order_lines` (`id`),
  CONSTRAINT `inventory_parts_rma_purchase_order_id_fkey` FOREIGN KEY (`rma_purchase_order_id`) REFERENCES `inventory_purchase_orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `inventory_parts_sku_id_fkey` FOREIGN KEY (`sku_id`) REFERENCES `inventory_skus` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000075 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_purchase_order_lines`
--

DROP TABLE IF EXISTS `inventory_purchase_order_lines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_purchase_order_lines` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `price` decimal(10,2) DEFAULT NULL,
  `purchased_quantity` int(11) DEFAULT '0',
  `sku_id` bigint(20) unsigned NOT NULL,
  `purchase_order_id` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `inventory_purchase_order_lines_sku_id_fkey` (`sku_id`),
  KEY `inventory_purchase_order_lines_purchase_order_id_fkey` (`purchase_order_id`),
  CONSTRAINT `inventory_purchase_order_lines_purchase_order_id_fkey` FOREIGN KEY (`purchase_order_id`) REFERENCES `inventory_purchase_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `inventory_purchase_order_lines_sku_id_fkey` FOREIGN KEY (`sku_id`) REFERENCES `inventory_skus` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000006 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_purchase_order_lines`
--

LOCK TABLES `inventory_purchase_order_lines` WRITE;
/*!40000 ALTER TABLE `hal_test`.`inventory_purchase_order_lines` DISABLE KEYS */;
INSERT INTO `inventory_purchase_order_lines` VALUES (1000001,1187.49,10,1000001,1000001);
/*!40000 ALTER TABLE `hal_test`.`inventory_purchase_order_lines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_purchase_orders`
--

DROP TABLE IF EXISTS `inventory_purchase_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_purchase_orders` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `po_number` varchar(255) DEFAULT NULL,
  `shipping_price` decimal(10,2) DEFAULT NULL,
  `sales_tax` decimal(10,2) DEFAULT NULL,
  `vendor_quote_number` varchar(255) DEFAULT NULL,
  `vendor_so_number` varchar(255) DEFAULT NULL,
  `vendor_invoice_number` varchar(255) DEFAULT NULL,
  `vendor_invoice_date` datetime DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `sent_at` datetime DEFAULT NULL,
  `beansbooks_id` bigint(20) unsigned DEFAULT NULL,
  `vendor_id` bigint(20) unsigned NOT NULL,
  `remit_address_id` int(10) unsigned NOT NULL,
  `shipping_address_id` int(10) unsigned NOT NULL,
  `account` varchar(255) NOT NULL,
  `shipping_method` varchar(255) DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `remainder_purchase_order_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inventory_purchase_orders_beansbooks_id_index` (`beansbooks_id`),
  UNIQUE KEY `inventory_purchase_orders_po_number_index` (`po_number`),
  KEY `inventory_purchase_orders_vendor_id_fkey` (`vendor_id`),
  KEY `inventory_purchase_orders_remit_address_id_fkey` (`remit_address_id`),
  KEY `inventory_purchase_orders_shipping_address_id_fkey` (`shipping_address_id`),
  KEY `inventory_purchase_orders_remainder_purchase_order_id_fkey` (`remainder_purchase_order_id`),
  FULLTEXT KEY `inventory_purchase_orders_search` (`po_number`,`vendor_quote_number`,`vendor_so_number`,`vendor_invoice_number`,`account`),
  CONSTRAINT `inventory_purchase_orders_remainder_purchase_order_id_fkey` FOREIGN KEY (`remainder_purchase_order_id`) REFERENCES `inventory_purchase_orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `inventory_purchase_orders_remit_address_id_fkey` FOREIGN KEY (`remit_address_id`) REFERENCES `addresses` (`id`),
  CONSTRAINT `inventory_purchase_orders_shipping_address_id_fkey` FOREIGN KEY (`shipping_address_id`) REFERENCES `addresses` (`id`),
  CONSTRAINT `inventory_purchase_orders_vendor_id_fkey` FOREIGN KEY (`vendor_id`) REFERENCES `inventory_vendors` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000018 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_purchase_orders`
--

LOCK TABLES `inventory_purchase_orders` WRITE;
/*!40000 ALTER TABLE `hal_test`.`inventory_purchase_orders` DISABLE KEYS */;
INSERT INTO `inventory_purchase_orders` VALUES (1000001,'1',25.00,1.00,NULL,NULL,NULL,NULL,'2020-10-08 19:30:25','2020-10-08 19:30:25','2019-01-01 00:00:00',1,1000002,1000002,1000001,'net 30 payable',NULL,'2019-01-20 00:00:00',NULL);
/*!40000 ALTER TABLE `hal_test`.`inventory_purchase_orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_skus`
--

DROP TABLE IF EXISTS `inventory_skus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_skus` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `sku` varchar(255) NOT NULL,
  `kind` varchar(255) NOT NULL,
  `serialized` tinyint(1) DEFAULT '0',
  `removed` tinyint(1) DEFAULT '0',
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `manufacturer_id` bigint(20) unsigned NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `reorder_quantity` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inventory_skus_sku_manufacturer_id_index` (`sku`,`manufacturer_id`),
  KEY `inventory_skus_manufacturer_id_fkey` (`manufacturer_id`),
  KEY `inventory_skus_type_index` (`kind`),
  FULLTEXT KEY `inventory_skus_search` (`sku`,`kind`,`description`),
  CONSTRAINT `inventory_skus_manufacturer_id_fkey` FOREIGN KEY (`manufacturer_id`) REFERENCES `inventory_manufacturers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000078 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_vendors`
--

DROP TABLE IF EXISTS `inventory_vendors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hal_test`.`inventory_vendors` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `phone_number` varchar(255) DEFAULT NULL,
  `company_name` varchar(255) NOT NULL,
  `beansbooks_account_id` int(11) DEFAULT NULL,
  `remit_address_id` int(10) unsigned DEFAULT NULL,
  `payable_account` varchar(255) NOT NULL DEFAULT 'net_0_payable',
  PRIMARY KEY (`id`),
  KEY `vendors_remit_address_id_fkey` (`remit_address_id`),
  FULLTEXT KEY `inventory_vendors_search` (`first_name`,`last_name`,`email`,`company_name`),
  CONSTRAINT `vendors_remit_address_id_fkey` FOREIGN KEY (`remit_address_id`) REFERENCES `addresses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1000029 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_vendors`
--

LOCK TABLES `inventory_vendors` WRITE;
/*!40000 ALTER TABLE `hal_test`.`inventory_vendors` DISABLE KEYS */;
INSERT INTO `inventory_vendors` VALUES (1000001,'System76','Vendor','admin@system76.com','7202269269','System76',1,1000001,'net 0 payable');
/*!40000 ALTER TABLE `hal_test`.`inventory_vendors` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-12-03 14:53:42
