
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'B1@blabla';
ALTER USER 'admin'@'localhost' IDENTIFIED WITH mysql_native_password BY 'B1@blabla';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
CREATE USER 'admin'@'%' IDENTIFIED BY 'B1@blabla';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
CREATE DATABASE hotels;
CREATE TABLE hotels.hotel_rooms (
    id int NOT NULL AUTO_INCREMENT,
    available_amount int NOT NULL,
    required_score int NOT NULL,
    room_name varchar(100) NOT NULL,
    PRIMARY KEY (id)
);
CREATE TABLE hotels.users (
    id int NOT NULL AUTO_INCREMENT,
    available_score int NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE hotels.deals (
    id int NOT NULL AUTO_INCREMENT,
    deal_timestamp TIMESTAMP NOT NULL,
    deal_status ENUM ('PENDING_APPROVAL','RESERVED'),
    room_id int NOT NULL,
    user_id int NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE hotels.monitor (
	tablename varchar(100) NOT NULL,
    columnname varchar(100) NOT NULL,
    id int NOT NULL,
    action_time TIMESTAMP NOT NULL,
    val varchar(100) NOT NULL,
    action_name varchar(100) NOT NULL
);

DROP PROCEDURE IF EXISTS hotels.close_room;
DELIMITER $$
CREATE PROCEDURE hotels.close_room(IN uid INT,IN roomName varchar(100),INOUT dealId INT, OUT isSuccess bool)
	proc_label:BEGIN
 #we can decide that api request already comes with the deal id. I found more user friendly to make it with a name 
	SET @roomId = (select id from hotels.hotel_rooms where room_name = roomName); 
	SET @requiredScore = (select required_score from hotels.hotel_rooms where id = @roomId);
 
	start transaction;
	SELECT * FROM hotels.hotel_rooms  WHERE id = @roomId FOR UPDATE;
	SELECT * FROM hotels.users  WHERE id = uid FOR UPDATE; 
    
	SET @hotelRoomAmount = (select available_amount from hotels.hotel_rooms where id = @roomId);
	SET @userPoints = (select available_score from hotels.users where id = uid);
	
	IF @userPoints is NULL OR @userPoints < @requiRedScore OR  @hotelRoomAmount = 0 THEN
		IF (dealId is not null) THEN
		BEGIN
			update hotels.deals set deal_timestamp = now() where id = dealId;
            #insert into hotels.monitor here
		END;
		ELSE
		BEGIN
			INSERT INTO hotels.deals(deal_status, room_id, user_id, deal_timestamp) VALUES('PENDING_APPROVAL', @roomId, uid, now());
            SET dealId = (SELECT LAST_INSERT_ID());
            #insert into hotels.monitor here
		END;
        END IF;
		SET isSuccess = 0;
	ELSE
		update hotels.hotel_rooms set available_amount = available_amount - 1 where id = @roomId;
        #insert into hotels.monitor here
		update hotels.users set available_score = available_score - @requiredScore where id = uid;
		#insert into hotels.monitor here

		IF (dealId is not null) THEN
		BEGIN
			update hotels.deals set deal_status = 'RESERVED', deal_timestamp = now() where id = dealId;
        	#insert into hotels.monitor here
		END;
		ELSE
		BEGIN
			INSERT INTO hotels.deals(deal_status, room_id, user_id, deal_timestamp) VALUES('RESERVED', @roomId, uid, now());
            SET dealId = (SELECT LAST_INSERT_ID());
        	#insert into hotels.monitor here

		END;
		END IF;
		SET isSuccess = 1;
	END IF;
	commit;
END$$
