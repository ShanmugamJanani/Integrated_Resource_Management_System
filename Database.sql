SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Database: `min_project`
--

-- --------------------------------------------------------

--
-- Table structure for table `book`
--

CREATE TABLE `book` (
  `Book_Id` varchar(20) NOT NULL,
  `ISBN` varchar(17) NOT NULL,
  `Book_Name` varchar(100) NOT NULL,
  `Author` varchar(100) NOT NULL,
  `Publication` varchar(100) NOT NULL,
  `Year` int(4) NOT NULL,
  `Category` varchar(100) NOT NULL,
  `No_Of_Copies` int(11) NOT NULL,
  `Book_Image` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` int(11) NOT NULL,
  `category_title` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- --------------------------------------------------------

--
-- Table structure for table `deletedfiles`
--

CREATE TABLE `deletedfiles` (
  `File_Id` varchar(200) NOT NULL,
  `File_Name` varchar(200) NOT NULL,
  `Record_RoomNo_Old` varchar(200) NOT NULL,
  `No_Of_MinitSheets` int(11) NOT NULL,
  `Year` year(4) NOT NULL,
  `Cupboard_No` varchar(200) NOT NULL,
  `Rack_No` varchar(200) NOT NULL,
  `Docket_No` varchar(200) NOT NULL,
  `Position_at_Docket` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `docket`
--

CREATE TABLE `docket` (
  `Docket_No` int(11) NOT NULL,
  `Size` int(11) NOT NULL DEFAULT 100,
  `Cupboard_No` int(11) NOT NULL,
  `Rack_No` int(11) NOT NULL,
  `Status` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


--
-- Triggers `docket`
--
DELIMITER $$
CREATE TRIGGER `before_docket_delete` BEFORE DELETE ON `docket` FOR EACH ROW BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Handle the exception
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred while deleting the docket';
    END;

    -- Update specific columns to NULL or a default value before deleting the row
    UPDATE docket
    SET Cupboard_No = NULL, Rack_No = NULL, Status = 0
    WHERE Docket_No = OLD.Docket_No;

    -- Move files to deletedFiles
    INSERT INTO deletedFiles
    SELECT *
    FROM file
    WHERE Docket_No = OLD.Docket_No;

    -- Delete files from the original table
    DELETE FROM file
    WHERE Docket_No = OLD.Docket_No;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_docket_delete2` BEFORE DELETE ON `docket` FOR EACH ROW BEGIN
    -- Update specific columns to NULL or a default value before deleting the row
    UPDATE docket
    SET Cupboard_No = NULL, Rack_No = NULL, Status = 0
    WHERE Docket_No = OLD.Docket_No;

    -- Move files to deletedFiles
    INSERT INTO deletedFiles
    SELECT *
    FROM file
    WHERE Docket_No = OLD.Docket_No;

    -- Delete files from the original table
    DELETE FROM file
    WHERE Docket_No = OLD.Docket_No;

    -- If there is no handler, any error will be reported as it is
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `file`
--

CREATE TABLE `file` (
  `Record_Room_No` char(14) NOT NULL,
  `File_Id` varchar(200) NOT NULL,
  `File_Name` varchar(200) NOT NULL,
  `No_Of_MinitSheets` int(11) NOT NULL,
  `Year` year(4) NOT NULL,
  `Cupboard_No` int(10) NOT NULL,
  `Rack_No` int(11) NOT NULL,
  `Docket_No` int(11) NOT NULL,
  `Position_at_Docket` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


--
-- Triggers `file`
--
DELIMITER $$
CREATE TRIGGER `set_position_and_RecordRoomNo` BEFORE INSERT ON `file` FOR EACH ROW BEGIN

DECLARE position INT;
DECLARE DockNo INT;
DECLARE RRN VARCHAR(15);

SET DockNo = NEW.Docket_No ;

    IF (SELECT COUNT(*) FROM file WHERE Docket_No = DockNo)  = 0 THEN
        SET NEW.Position_at_Docket = 1;
       
    ELSE
    SELECT Position_at_Docket INTO position
        FROM file WHERE Docket_No = DockNo
        ORDER BY Position_at_Docket DESC
        LIMIT 1;
       
        SET NEW.Position_at_Docket = position + 1;   
    END IF;
    
    SET RRN = CONCAT('R-', LPAD(NEW.Cupboard_No, 2, '0'), '-', LPAD(NEW.Rack_No, 2, '0'), '-', LPAD(NEW.Docket_No, 2, '0'), '-', LPAD(NEW.Position_at_Docket,3,'0'));

    
    SET NEW.Record_Room_No = RRN;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `fine_amount`
--

CREATE TABLE `fine_amount` (
  `nic` varchar(100) NOT NULL,
  `Fine_Amount` decimal(10,0) NOT NULL,
  `Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `issued_item`
--

CREATE TABLE `issued_item` (
  `Section_Id` char(6) NOT NULL,
  `Item_Id` varchar(20) NOT NULL,
  `Quantity` bigint(20) NOT NULL,
  `Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- --------------------------------------------------------

--
-- Table structure for table `issue_book`
--

CREATE TABLE `issue_book` (
  `nic` varchar(100) NOT NULL,
  `Book_Id` varchar(20) NOT NULL,
  `ISBN` varchar(17) NOT NULL,
  `Book_Name` varchar(100) NOT NULL,
  `Author` varchar(100) NOT NULL,
  `Year` int(4) NOT NULL,
  `Category` varchar(100) NOT NULL,
  `username` varchar(200) NOT NULL,
  `issued_date` date NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `item`
--

CREATE TABLE `item` (
  `Item_Id` varchar(200) NOT NULL,
  `Item_name` varchar(200) NOT NULL,
  `CurrentBalance` bigint(20) NOT NULL,
  `Open_Balance` bigint(20) NOT NULL DEFAULT 0,
  `Replishment` int(11) NOT NULL,
  `ReorderNeeded` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- --------------------------------------------------------

--
-- Table structure for table `permission`
--

CREATE TABLE `permission` (
  `nic` varchar(100) NOT NULL,
  `file_tracking` varchar(20) NOT NULL,
  `library_management` varchar(20) NOT NULL,
  `inventory` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `purchased_item` (
  `Item_Id` varchar(20) NOT NULL,
  `Quantity` bigint(20) NOT NULL,
  `Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- --------------------------------------------------------

--
-- Table structure for table `request_book`
--

CREATE TABLE `request_book` (
  `nic` varchar(100) NOT NULL,
  `Book_Id` varchar(20) NOT NULL,
  `ISBN` varchar(17) NOT NULL,
  `Book_Name` varchar(100) NOT NULL,
  `Author` varchar(100) NOT NULL,
  `Year` int(4) NOT NULL,
  `Category` varchar(100) NOT NULL,
  `username` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



-- --------------------------------------------------------

--
-- Table structure for table `return_book`
--

CREATE TABLE `return_book` (
  `nic` varchar(100) NOT NULL,
  `Book_Id` int(20) NOT NULL,
  `ISBN` varchar(17) NOT NULL,
  `Book_Name` varchar(100) NOT NULL,
  `Author` varchar(100) NOT NULL,
  `Year` int(4) NOT NULL,
  `Category` varchar(100) NOT NULL,
  `username` varchar(200) NOT NULL,
  `issue_date` date NOT NULL,
  `return_date` date DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;




-- --------------------------------------------------------

--
-- Table structure for table `section`
--

CREATE TABLE `section` (
  `Section_Id` char(6) NOT NULL,
  `Section_Name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `first_name` varchar(500) NOT NULL,
  `last_name` varchar(500) NOT NULL,
  `nic` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `username` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- --------------------------------------------------------

--
-- Table structure for table `user_temp`
--

CREATE TABLE `user_temp` (
  `first_name` varchar(500) NOT NULL,
  `last_name` varchar(500) NOT NULL,
  `nic` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `username` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


--
-- Indexes for dumped tables
--

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`);

--
-- Indexes for table `deletedfiles`
--
ALTER TABLE `deletedfiles`
  ADD PRIMARY KEY (`File_Id`);

--
-- Indexes for table `docket`
--
ALTER TABLE `docket`
  ADD PRIMARY KEY (`Docket_No`);

--
-- Indexes for table `file`
--
ALTER TABLE `file`
  ADD PRIMARY KEY (`Record_Room_No`),
  ADD UNIQUE KEY `File_Id` (`File_Id`);

--
-- Indexes for table `fine_amount`
--
ALTER TABLE `fine_amount`
  ADD PRIMARY KEY (`nic`),
  ADD KEY `fk_fineamount_nic` (`nic`);

--
-- Indexes for table `issued_item`
--
ALTER TABLE `issued_item`
  ADD PRIMARY KEY (`Section_Id`,`Item_Id`,`Quantity`,`Date`),
  ADD KEY `FK_Item_Id` (`Item_Id`);

--
-- Indexes for table `item`
--
ALTER TABLE `item`
  ADD PRIMARY KEY (`Item_Id`),
  ADD UNIQUE KEY `Item_name` (`Item_name`);

--
-- Indexes for table `permission`
--
ALTER TABLE `permission`
  ADD PRIMARY KEY (`nic`);

--
-- Indexes for table `purchased_item`
--
ALTER TABLE `purchased_item`
  ADD PRIMARY KEY (`Item_Id`,`Quantity`,`Date`);

--
-- Indexes for table `section`
--
ALTER TABLE `section`
  ADD PRIMARY KEY (`Section_Id`),
  ADD UNIQUE KEY `Section_Name` (`Section_Name`),
  ADD UNIQUE KEY `Section_Id` (`Section_Id`,`Section_Name`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`nic`);

--
-- Indexes for table `user_temp`
--
ALTER TABLE `user_temp`
  ADD PRIMARY KEY (`nic`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
