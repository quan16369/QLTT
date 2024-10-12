create database Doan
	use Doan
use bt5
drop database doan

CREATE TABLE NguoiDung (
    MaND INT PRIMARY KEY , 
    TenND VARCHAR(50) UNIQUE NOT NULL, 
    Email VARCHAR(100) UNIQUE NOT NULL, 
    MK VARCHAR(100) NOT NULL, 
    NgaySinh DATE NOT NULL, 
    GT VARCHAR(10) NOT NULL
);

CREATE TABLE DuLieuSK (
    MaDL INT PRIMARY KEY , 
    MaND INT, 
    HD VARCHAR(30), 
    NgayGN DATE, 
    ChieuCao DECIMAL(5, 2),
    CanNang DECIMAL(5, 2), 
    TinhTrang VARCHAR(30), 
    FOREIGN KEY (MaND) REFERENCES NguoiDung(MaND) 
);

CREATE TABLE BaiTap (
    MaBT INT PRIMARY KEY , 
    Ten VARCHAR(100), 
    CaloTH_BT FLOAT
);

CREATE TABLE BT_ND (
    MaBTND INT PRIMARY KEY , 
	MaND INT, 
    MaBT INT, 
    Ngay DATE, 
    TGThucHien INT, 
    CaloTH FLOAT,
    FOREIGN KEY (MaBT) REFERENCES BaiTap(MaBT), 
	FOREIGN KEY (MaND) REFERENCES NguoiDung(MaND) 
);

CREATE TABLE MucTieu (
    MaMT INT PRIMARY KEY , 
    MaND INT,  
    TenMT VARCHAR(100), 
    ThoiHan DATE, 
	DatDuoc CHAR(1) DEFAULT '0',
    FOREIGN KEY (MaND) REFERENCES NguoiDung(MaND) 
);


ALTER TABLE DuLieuSK
ADD CONSTRAINT CK_HD
CHECK (HD IN ('it hoat dong', 'hoat dong nhe', 'hoat dong vua phai', 'hoat dong nang', 'hoat dong rat nang'));

ALTER TABLE NguoiDung
ADD CONSTRAINT CK_Email_Format
CHECK (Email LIKE '%@%');

ALTER TABLE NguoiDung
ADD CONSTRAINT CK_GT
CHECK (GT IN ('nam', 'nu'));

ALTER TABLE DuLieuSK
ADD CONSTRAINT CK_TinhTrang
CHECK (TinhTrang IN ('gay do III', 'gay do II', 'gay do Ii', 'binh thuong', 'thua can', 'beo phi do I', 'beo phi do II', 'beo phi do III'));

ALTER TABLE MucTieu
ADD CONSTRAINT CK_TenMT
CHECK (TenMT IN ('giam can', 'tang can', 'giu can'));

ALTER TABLE MucTieu
ADD CONSTRAINT CK_DatDuoc
CHECK (DatDuoc IN ('0', '1'));

--Trigger tự động cập nhật TinhTrang dựa trên BMI khi thêm dữ liệu mới vào bảng DuLieuSK

CREATE TRIGGER Update_TinhTrang_DuLieuSK
ON DuLieuSK
AFTER INSERT, UPDATE
AS
BEGIN
    -- Cập nhật trường BMI và TinhTrang dựa trên các dữ liệu mới được chèn hoặc cập nhật
    UPDATE d
    SET d.TinhTrang = 
        CASE 
            WHEN (d.CanNang / POWER(d.ChieuCao , 2)) < 16 THEN 'gay do III'
            WHEN (d.CanNang / POWER(d.ChieuCao, 2)) BETWEEN 16 AND 16.9 THEN 'gay do II'
            WHEN (d.CanNang / POWER(d.ChieuCao, 2)) BETWEEN 17 AND 17.9 THEN 'gay do I'
            WHEN (d.CanNang / POWER(d.ChieuCao, 2)) BETWEEN 18.5 AND 24.9 THEN 'binh thuong'
            WHEN (d.CanNang / POWER(d.ChieuCao, 2)) BETWEEN 25 AND 29.9 THEN 'thua can'
            WHEN (d.CanNang / POWER(d.ChieuCao, 2)) BETWEEN 30 AND 34.9 THEN 'beo phi do I'
            WHEN (d.CanNang / POWER(d.ChieuCao, 2)) BETWEEN 35 AND 39.9 THEN 'beo phi do II'
            ELSE 'beo phi do III'
        END
    FROM DuLieuSK d
    INNER JOIN INSERTED i ON d.MaDL = i.MaDL;
END;

-- Trigger tự động cập nhật DatDuoc dựa  trên Ten_MT và ThoiHan 
CREATE TRIGGER Update_DatDuoc_DuLieuSK
ON DuLieuSK
AFTER INSERT, UPDATE
AS
BEGIN
    -- Cập nhật cột DatDuoc trong bảng MucTieu cho mục tiêu giảm cân
    UPDATE MucTieu
    SET DatDuoc = '1'
    FROM MucTieu m
    INNER JOIN DuLieuSK d ON m.MaND = d.MaND
    WHERE m.TenMT = 'giam can'
      AND m.ThoiHan = d.NgayGN
      AND d.CanNang < (
          SELECT TOP 1 CanNang
          FROM DuLieuSK
          WHERE MaND = m.MaND
          ORDER BY NgayGN ASC
      )
	  AND m.DatDuoc = '0'
    
    -- Cập nhật cột DatDuoc trong bảng MucTieu cho mục tiêu giữ cân
    UPDATE MucTieu
    SET DatDuoc = '1'
    FROM MucTieu m
    INNER JOIN DuLieuSK d ON m.MaND = d.MaND
    WHERE m.TenMT = 'giu can'
      AND m.ThoiHan = d.NgayGN
      AND d.CanNang = (
          SELECT TOP 1 CanNang
          FROM DuLieuSK
          WHERE MaND = m.MaND
          ORDER BY NgayGN ASC
      )
	   AND m.DatDuoc = '0'

    -- Cập nhật cột DatDuoc trong bảng MucTieu cho mục tiêu tăng cân
    UPDATE MucTieu
    SET DatDuoc = '1'
    FROM MucTieu m
    INNER JOIN DuLieuSK d ON m.MaND = d.MaND
    WHERE m.TenMT = 'tang can'
      AND m.ThoiHan = d.NgayGN
      AND d.CanNang > (
          SELECT TOP 1 CanNang
          FROM DuLieuSK
          WHERE MaND = m.MaND
          ORDER BY NgayGN ASC
      )
	  AND m.DatDuoc = '0'
    
END;

--Trigger kiểm tra ngày sinh với ngày ghi nhận
CREATE TRIGGER KT_NS_NGN  ON DuLieuSK
FOR INSERT,UPDATE
AS
BEGIN
	DECLARE @MAND INT,@NS DATE,@NGN DATE

		SELECT @NGN = NgayGN
		FROM DuLieuSK

		SELECT @NS = NgaySinh
		FROM NguoiDung
		WHERE @MAND = MaND

	IF (@NS>@NGN)
		BEGIN
			PRINT N'LỖI NGÀY SINH LỚN HƠN NGÀY GHI NHẬN '
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			PRINT N'CẬP NHẬT DỮ LIỆU THÀNH CÔNG'
		END
END

-- Trigger ThoiHan phải lớn hơn hoặc bằng NgayGN
CREATE TRIGGER KT_NGN_TH_MT
ON MucTieu
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DuLieuSK d ON i.MaND = d.MaND
        WHERE i.ThoiHan < d.NgayGN
    )
    BEGIN
        PRINT N'ThoiHan phải lớn hơn hoặc bằng NgayGN.'
        ROLLBACK TRANSACTION
    END
END;

-- Trigger tính caloTH = CaloTH_BT*TGThucHien*60
CREATE TRIGGER Update_CALO ON BT_ND
AFTER INSERT,UPDATE 
AS 
BEGIN

UPDATE BT_ND
SET CaloTH  = cast((TGThucHien)as float) * bt.CaloTH_BT *60
FROM BT_ND
    INNER JOIN BaiTap bt ON BT_ND.MaBT = bt.MaBT
    WHERE BT_ND.MaBT IN (SELECT MaBT FROM inserted)
END;



SET DATEFORMAT DMY 

insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (92, 'Nguyen Van A', 'nathan.kelly@gmail.com', 'P@ssw0rd2050', '22/08/1988', 'nam');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (85, 'Tang Thi T', 'samuel.young@gmail.com', 'P@ssw0rd2026', '12/10/1998', 'nam');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (64, 'Linh Thi AI', 'john.doe@gmail.com', 'Str0ngP@ss', '12/01/1997', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (59, 'Quyen Thi AG', 'zoe.peterson@gmail.com', 'P@ssw0rd2022', '12/12/1997', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (81, 'Yen Thi DAY', 'john1.doe@gmail.com', 'P@ssw0rd2024', '28/05/2004', 'nam');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (50, 'Kieu Van U', 'scarlett.ward@gmail.com', 'P@ssw0rd2064', '01/06/1985', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (66, 'Ngo Thi J', 'ryan.mitchell@gmail.com', 'P@ssw0rd2043', '21/09/1990', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (77, 'Quach Thi R', 'david.brown@gmail.com', 'P@ssw0rd2050', '04/04/1994', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (72, 'Ha Thi P', 'alexander.wang@gmail.com', 'P@ssw0rd2033', '18/04/1980', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (78, 'Lam Thi Z', 'james.clark@gmail.com', 'P@ssw0rd!', '21/11/2002', 'nam');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (27, 'Son Van AV', 'emily.wilson@gmail.com', 'P@ssw0rd2022', '01/11/1990', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (28, 'Nga Thi AW', 'ethan.lewis@gmail.com', 'P@ssw0rd2058', '06/05/1991', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (26, 'Tien Van AJ', 'olivia.miller@gmail.com', 'P@ssw0rd2036', '27/03/2002', 'nam');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (43, 'Ly Thi L', 'matthew.russell@gmail.com', 'P@ssw0rd2064', '29/03/1995', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (98, 'Ly Thi LY', 'ella.collins@gmail.com', 'P@ssw0rd2046', '29/07/1984', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (7, 'Thuy Thi AU', 'andrew.murphy@gmail.com', 'P@ssw0rd2052', '01/08/1997', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (99, 'Tran Thi B', 'zoe1.peterson@gmail.com', 'P@ssw0rd2050', '10/11/1999', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (44, 'Yen Thi AY', 'wyatt.gonzalez@gmail.com', 'P@ssw0rd2051', '20/02/1985', 'nam');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (35, 'Minh Thi AM', 'luke.watson@gmail.com', 'P@ssw0rd2058', '27/12/1990', 'nu');
insert into NguoiDung (MaND, TenND, Email, MK, NgaySinh, GT) values (8, 'Tang Thi DT', 'mia.hall@gmail.com', 'P@ssw0rd2026', '07/12/1995', 'nu');

INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (42, 26, 'it hoat dong', '14/12/2021', 1.68, 81, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (76, 81,'hoat dong rat nang', '22/03/2022', 1.72, 90, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (23, 78, 'hoat dong rat nang', '30/01/2022', 1.72, 78, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (65, 44, 'it hoat dong', '27/02/2022', 1.7, 44, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (34, 27, 'hoat dong rat nang', '15/11/2021', 1.9, 84, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (95, 85, 'hoat dong rat nang', '11/10/2022', 1.72, 87, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (80, 43,  'hoat dong nang', '15/02/2022', 1.71, 70, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (81, 66, 'hoat dong rat nang', '27/03/2022', 1.8, 78, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (99, 81, 'it hoat dong', '15/03/2022', 1.95, 63, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (38, 81, 'hoat dong vua phai', '29/08/2022', 1.78, 41, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (5, 26,'hoat dong vua phai', '26/02/2020', 1.99, 49, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (39, 44, 'hoat dong nang', '19/04/2021', 1.89, 43, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (86, 78, 'hoat dong vua phai', '26/04/2021', 1.96, 54, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (13, 81, 'it hoat dong', '14/07/2020', 1.99, 96, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (87, 66, 'it hoat dong', '11/01/2021', 1.72, 47, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (35, 77, 'hoat dong vua phai', '11/07/2020', 1.76, 79, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (64, 7,  'hoat dong vua phai', '23/06/2022', 1.92, 53, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (91, 72, 'hoat dong nhe', '27/11/2023', 1.9, 46, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (70, 66, 'hoat dong nang', '23/09/2020', 1.75, 87, NULL);
INSERT INTO DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) VALUES (14, 78,'hoat dong vua phai', '07/08/2021', 1.69, 93, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (6, 27, 'it hoat dong', '27/11/2020', 1.83, 88, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (31, 50, 'hoat dong vua phai', '14/11/2020', 1.63, 77, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (85, 98, 'hoat dong nang', '27/8/2021', 1.82, 72, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (16, 98, 'hoat dong nhe', '11/1/2021', 1.7, 90, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (54, 8, 'hoat dong nhe', '21/8/2021', 1.68, 76, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (20, 7, 'hoat dong nhe', '27/1/2021', 1.63, 73, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (62, 72, 'it hoat dong', '14/4/2021', 1.78, 43, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (60, 43, 'hoat dong nang', '28/11/2021', 1.68, 74, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (9, 85, 'hoat dong nhe', '21/3/2022', 1.95, 71, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (11, 98, 'it hoat dong', '31/1/2024', 1.87, 82, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (67, 7, 'hoat dong rat nang', '12/5/2022', 1.64, 96, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (66, 81, 'hoat dong nhe', '11/8/2020', 1.92, 61, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (10, 35, 'hoat dong nhe', '26/4/2022', 1.65, 41, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (45, 81,  'it hoat dong', '23/11/2021', 1.9, 62, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (98, 44, 'hoat dong nang', '5/7/2019', 1.68, 45, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (15, 44, 'it hoat dong', '4/1/2021', 1.9, 63, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (89, 66,'hoat dong nhe', '3/4/2021', 1.67, 54, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (82, 27, 'hoat dong vua phai', '29/2/2020', 1.72, 73, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (3, 28, 'hoat dong nhe', '16/7/2022', 1.91, 43, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (100, 44, 'it hoat dong', '4/10/2022', 1.72, 96, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (101, 50,'hoat dong vua phai', '13/7/2021', 1.86, 62, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (17, 92, 'hoat dong nhe', '4/5/2020', 1.8, 60, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (48, 78, 'hoat dong nhe', '10/3/2021', 1.95, 89, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (92, 43, 'hoat dong nhe', '22/2/2022', 1.95, 66, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (36, 43, 'it hoat dong', '27/9/2020', 1.81, 93, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (102, 44,'it hoat dong', '1/8/2023', 1.69, 45, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (63, 50,'hoat dong vua phai', '5/5/2021', 1.73, 43, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (19, 72, 'hoat dong nhe', '9/9/2022', 1.66, 74, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (71, 26,'hoat dong nang', '27/4/2022', 1.66, 95, NULL);
insert into DuLieuSK (MaDL, MaND, HD, NgayGN, ChieuCao, CanNang, TinhTrang) values (43, 98, 'hoat dong nang', '2/10/2021', 1.8, 83, NULL);

insert into BaiTap (MaBT, Ten, CaloTH_BT) values (95, 'Chay bo', 12.5);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (3, 'Di bo', 6.67);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (22, 'Dap xe', 12.5);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (37, 'Boi loi', 10);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (82, 'Tap ta', 4.83);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (61, 'Yoga', 5);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (99, 'Pilates', 5);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (13, 'Tap luyen HIIT', 11.67);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (45, 'Plank', 0.67);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (89, 'Squats', 5.58);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (48, 'Push-ups', 5.58);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (63, 'Lunges', 5.58);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (77, 'Burpees', 8.33);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (60, 'Crunches', 2.5);
insert into BaiTap (MaBT, Ten, CaloTH_BT) values (20, 'Jumping Jacks', 5.83);

insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (45, 85, 20, '17/3/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (60, 8, 45, '2/9/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (68, 99, 63, '11/6/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (1001, 26, 37, '12/2/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (4, 27, 13, '21/8/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (86, 43, 99, '14/3/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (251, 59, 77, '24/12/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (802, 66, 45, '24/1/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (50, 44, 48, '1/12/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (142, 26, 13, '25/12/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (92, 50, 99, '16/4/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (91, 8, 20, '13/7/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (48, 7, 61, '19/5/2024', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (680, 85, 22, '31/3/2024', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (18, 26, 82, '6/9/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (77, 72, 20, '26/3/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (801, 59, 22, '4/11/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (88, 92, 60, '10/4/2024', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (64, 43, 61, '18/1/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (881, 35, 99, '24/11/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (28, 28, 37, '25/3/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (22, 7, 61, '28/2/2024', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (55, 50, 63, '11/1/2024', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (221, 85, 37, '14/5/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (32, 92, 60, '3/6/2024', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (89, 78, 61, '14/9/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (9, 81, 82, '4/12/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (501, 27, 99, '13/5/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (76, 98, 3, '18/9/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (38, 64, 63, '21/4/2024', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (97, 81, 89, '17/1/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (93, 85, 13, '15/2/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (7, 35, 3, '26/4/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (71, 98, 20, '23/4/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (640, 85, 61, '14/12/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (761, 8, 60, '31/10/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (63, 72, 37, '23/8/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (35, 44, 3, '6/12/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (550, 28, 60, '12/1/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (62, 26, 48, '8/3/2023', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (80, 77, 61, '24/5/2024', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (25, 66, 45, '11/2/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (99, 7, 45, '1/10/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (100, 92, 61, '4/2/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (14, 43, 60, '10/2/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (65, 28, 45, '26/6/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (641, 35, 63, '30/4/2024', 1, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (803, 64, 13, '21/10/2023', 2, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (632, 98, 63, '9/9/2023', 3, NULL);
insert into BT_ND (MaBTND, MaND,MaBT,Ngay,TGThucHien,CaloTH) values (73, 78, 45, '11/4/2023', 1, NULL);

insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (1, 26, 'giam can', '13/6/2026');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (2, 99, 'giam can', '25/8/2027');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (3, 81, 'giam can', '4/5/2027');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (4, 35, 'giam can', '26/8/2025');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (5, 50, 'giam can', '7/8/2027');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (6, 92, 'giu can', '19/10/2025');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (7, 8, 'giam can', '11/7/2024');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (8, 78, 'giam can', '10/5/2027');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (9, 28, 'giu can', '5/9/2025');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (10, 44, 'giam can', '19/2/2027');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (11, 77, 'giu can', '7/9/2025');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (12, 27, 'tang can', '12/10/2024');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (13, 66, 'giu can', '6/6/2026');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (14, 85, 'tang can', '1/11/2027');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (15, 72, 'tang can', '21/9/2026');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (16, 59, 'giam can', '6/2/2025');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (17, 43, 'giam can', '5/12/2026');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (18, 7, 'giam can', '13/11/2025');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (19, 98, 'tang can', '17/3/2026');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (20, 7, 'tang can', '25/5/2028');
insert into MucTieu (MaMT,MaND,TenMT,ThoiHan) values (21, 64, 'tang can', '10/2/2027');


--Procedure Tạo cập nhật khi người dùng nhập mới dữ liệu

GO
CREATE PROC MODIF_DS_ND 
    @MaND INT, 
    @TenND VARCHAR(50) = NULL, 
    @Email VARCHAR(100) = NULL, 
    @MK VARCHAR(100) = NULL
AS
BEGIN
    BEGIN TRY
        -- Kiểm tra xem MaND có tồn tại hay không
        IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE MaND = @MaND)
        BEGIN
            PRINT N'Không tìm thấy mã người dùng hợp lệ'
            RETURN 0
        END
        
        -- Biến lưu trữ câu lệnh SQL động
        DECLARE @SQL NVARCHAR(MAX) = 'UPDATE NguoiDung SET ';
        DECLARE @First BIT = 1;
        
        -- Thêm các trường cần cập nhật vào câu lệnh SQL động
        IF @TenND IS NOT NULL
        BEGIN
            SET @SQL = @SQL + 'TenND = @TenND';
            SET @First = 0;
        END
        
        IF @Email IS NOT NULL
        BEGIN
            IF @First = 0 SET @SQL = @SQL + ', ';
            SET @SQL = @SQL + 'Email = @Email';
            SET @First = 0;
        END
        
        IF @MK IS NOT NULL
        BEGIN
            IF @First = 0 SET @SQL = @SQL + ', ';
            SET @SQL = @SQL + 'MK = @MK';
        END
        
        SET @SQL = @SQL + ' WHERE MaND = @MaND';
        
        -- Thực thi câu lệnh SQL động
        EXEC sp_executesql @SQL, 
            N'@MaND INT, @TenND VARCHAR(50), @Email VARCHAR(100), @MK VARCHAR(100)', 
            @MaND = @MaND, 
            @TenND = @TenND, 
            @Email = @Email, 
            @MK = @MK;
        
        PRINT N'Cập nhật dữ liệu thành công'
        RETURN 1
    END TRY
    BEGIN CATCH
        -- Lấy thông tin lỗi chi tiết
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT N'Đã xảy ra lỗi khi cập nhật dữ liệu: ' + @ErrorMessage;
        RETURN -1
    END CATCH
END
GO

EXEC MODIF_DS_ND @MaND = 7, @TenND = 'Nguyen Van C', @Email = 'nguyenvanb@example.com';

-- Procedure Nhập thêm dữ liệu mới của người dùng
GO
CREATE PROC INS_DS_ND @MaND INT, @TenND VARCHAR(50), @Email VARCHAR(50), @MK VARCHAR(100), @NgaySinh DATE, @GT VARCHAR(50)
AS
BEGIN
	IF EXISTS( SELECT *
					FROM NguoiDung
					WHERE MaND = @MaND)
		BEGIN
			PRINT N'Đã có người dùng hợp lệ'
			RETURN 0
		END
	ELSE 
		BEGIN
			INSERT INTO NguoiDung VALUES(@MaND,@TenND,@Email,@MK,@NgaySinh,@GT)
			PRINT N'Thêm dữ liệu thành công'
			RETURN 1
		END
END

-- Procedure Thêm mới dữ liệu sức khoẻ

CREATE PROC INS_DS_SK @MaDL INT, @MaND INT, @HD VARCHAR(30), @NgayGN DATE, @ChieuCao DECIMAL(5,2), @CanNang DECIMAL(5,2)
AS
BEGIN
	IF NOT EXISTS( SELECT *
					FROM NguoiDung
					WHERE MaND = @MaND)
		BEGIN
			PRINT N'Không có người dùng hợp lệ'
			RETURN 0
		END
	ELSE 
		BEGIN
			INSERT INTO DuLieuSK VALUES(@MaDL, @MaND, @HD ,@NgayGN, @ChieuCao, @CanNang, NULL)
			PRINT N'Thêm dữ liệu thành công'
			RETURN 1
		END
END

-- Procedure Xoá dữ liệu liên quan tới người dùng

GO
CREATE PROC DEL_DS_ND @MaND INT
AS
BEGIN
	IF EXISTS( SELECT *
					FROM NguoiDung
					WHERE MaND = @MaND)
		BEGIN
			SET NOCOUNT ON;
			DELETE FROM DuLieuSK WHERE MaND = @MaND
			DELETE FROM BT_ND WHERE MaND = @MaND
			DELETE FROM MucTieu WHERE MaND = @MaND
	
			DELETE FROM NguoiDung WHERE MaND = @MaND
			PRINT N'Đã xoá người dùng khỏi hệ thống'		
			RETURN 1
		END
	ELSE 
		BEGIN
			PRINT N'Không tìm thấy dữ liệu mã người dùng thích hợp'
			RETURN 0
		END
END

--Function tính toán lượng calo cần tiêu hao để duy trì cân nặng hiện tại, tăng cân hoặc giảm cân của người dùng dựa trên hoạt động hàng ngày và thông tin sức khỏe.
create function TinhCaloCan(@MaND INT) returns float 
as
begin
	declare @BMR float,
			@Calories float, 
			@ChieuCao float, 
			@CanNang float,
			@Tuoi int, 
			@GT varchar(100), 
			@HD varchar(100), 
			@TenMT varchar(100)
	select
		@Tuoi = year(getdate()) - year(NgaySinh), 
		@ChieuCao = ChieuCao, 
		@CanNang = CanNang, 
		@GT = GT,
		@HD = HD
	from DuLieuSK inner join NguoiDung on DuLieuSK.MaND = NguoiDung.MaND
	where DuLieuSK.MaND = @MaND

	--Tìm mục tiêu chưa đạt được (tại một thời điểm chỉ có một mục tiêu chưa đạt)
	select @TenMT = TenMT 
	from MucTieu
	where MaND = @MaND and DatDuoc = '0'


	--Tùy theo giới tính, tính chỉ số BMR theo công thức Mifflin St Jeor
	if @GT = 'nam'
	begin 
		set @BMR = (10 * @CanNang) + (6.25 * @ChieuCao) - (5 * @Tuoi) + 5 
	end
	else if @GT = 'nu'
	begin
		set @BMR = (10 * @CanNang) + (6.25 * @ChieuCao) - (5 * @Tuoi) - 161
	end 


	--Tùy theo mức độ hoạt động, tăng chỉ số BMR (hoạt động càng nhiều, BMR càng lớn)
	if @HD = 'it hoat dong'
	begin 
		set @Calories = @BMR * 1.2
	end
	else if @HD = 'hoat dong nhe'
	begin
		set @Calories = @BMR * 1.375
	end
	else if @HD = 'hoat dong vua phai'
	begin 
		set @Calories = @BMR * 1.55
	end
	else if @HD = 'hoat dong nang'
	begin 
		set @Calories = @BMR * 1.725 
	end
	else if @HD = 'hoat dong rat nang'
	begin 
		set @Calories = @BMR * 1.9
	end

	--Dựa vào mục tiêu người dùng, tính lượng calories cần thiết
	if @TenMT = 'giam can'
	begin 
		set @Calories = @Calories - 500
	end
	else if @TenMT = 'tang can'
	begin 
		set @Calories = @Calories + 500
	end 

	return @Calories
end

--Gọi function tham số đầu vào là mã người dùng
select dbo.TinhCaloCan(28) as LuongCaloCanThiet
go

--Function tính thời gian người dùng đã tập cho một bài tập cụ thể
create function TinhThoiGianTap (@MaND int, @Ten varchar(MAX)) returns int
as 
begin 
	declare @TongThoiGian int

	if exists (select * 
				from NguoiDung nd, BaiTap bt, BT_ND bn
				where nd.MaND = bn.MaND
					and bn.MaBT = bt.MaBT
					and nd.MaND = @MaND
					and bt.Ten = @Ten) 
		begin 
			select @TongThoiGian = SUM(TGThucHien)
			from NguoiDung nd, BaiTap bt, BT_ND bn
			where nd.MaND = bn.MaND
				and bn.MaBT = bt.MaBT
				and nd.MaND = @MaND
				and bt.Ten = @Ten
		end
	else
		begin 
			set @TongThoiGian = 0
		end 
 
	return @TongThoiGian
end 

select dbo.TinhThoiGianTap(35,'Di bo') as TongSoGio

select dbo.TinhThoiGianTap(35,'Lam do an') as TongSoGio

drop function TinhThoiGianTap

select * from NguoiDung nd, BaiTap bt, BT_ND bn
where nd.MaND = bn.MaND
	and bn.MaBT = bt.MaBT


--Cursor để duyệt qua dữ liệu sức khỏe của người dùng và tạo báo cáo phản hồi.

-- Tạo stored procedure
CREATE PROCEDURE SucKhoe_ND
AS
BEGIN
    -- Tạo bảng tạm để lưu trữ kết quả
    CREATE TABLE #HealthReport (
        MaND INT,
        TenND VARCHAR(50),
        NgaySinh DATE,
        GT VARCHAR(10),
        HD VARCHAR(30),
        NgayGN DATE,
        ChieuCao DECIMAL(5, 2),
        CanNang DECIMAL(5, 2),
        TinhTrang VARCHAR(30),
    );

    -- Khai báo các biến cần thiết
    DECLARE @MaND INT;
    DECLARE @TenND VARCHAR(50);
    DECLARE @NgaySinh DATE;
    DECLARE @GT VARCHAR(10);
    DECLARE @HD VARCHAR(30);
    DECLARE @NgayGN DATE;
    DECLARE @ChieuCao DECIMAL(5, 2);
    DECLARE @CanNang DECIMAL(5, 2);
    DECLARE @TinhTrang VARCHAR(30);

    -- Khai báo con trỏ để duyệt qua dữ liệu sức khỏe của người dùng
    DECLARE health_cursor CURSOR FOR
    SELECT 
        nd.MaND, nd.TenND, nd.NgaySinh, nd.GT, 
        dls.HD, dls.NgayGN, dls.ChieuCao, dls.CanNang, 
        dls.TinhTrang
    FROM 
        NguoiDung nd
    JOIN 
        DuLieuSK dls ON nd.MaND = dls.MaND
    ORDER BY 
        nd.MaND, dls.NgayGN;

    -- Mở con trỏ
    OPEN health_cursor;

    -- Lấy hàng đầu tiên từ con trỏ
    FETCH NEXT FROM health_cursor INTO @MaND, @TenND, @NgaySinh, @GT, @HD, @NgayGN, @ChieuCao, @CanNang, @TinhTrang;

    -- Vòng lặp duyệt qua các hàng của con trỏ
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Thêm dòng dữ liệu vào bảng kết quả tạm thời
        INSERT INTO #HealthReport (MaND, TenND, NgaySinh, GT, HD, NgayGN, ChieuCao, CanNang, TinhTrang)
        VALUES (@MaND, @TenND, @NgaySinh, @GT, @HD, @NgayGN, @ChieuCao, @CanNang, @TinhTrang);

        -- Lấy hàng tiếp theo từ con trỏ
        FETCH NEXT FROM health_cursor INTO @MaND, @TenND, @NgaySinh, @GT, @HD, @NgayGN, @ChieuCao, @CanNang, @TinhTrang;
    END

    -- Đóng con trỏ
    CLOSE health_cursor;
    -- Giải phóng tài nguyên của con trỏ
    DEALLOCATE health_cursor;

    -- Trả về kết quả từ bảng tạm
    SELECT * FROM #HealthReport;

    -- Xóa bảng tạm
    DROP TABLE #HealthReport;
END;

EXEC SucKhoe_ND


--Tạo role 

create role Manager
create role Employee
create role User_role

--CẤP QUYỀN ROLE MANAGER
--bảng
grant select, insert, update, delete on NguoiDung to Manager
grant select, insert, update on DuLieuSK to Manager
grant select, insert, update on BaiTap to Manager
grant select, insert, update on BT_ND to Manager 
grant select, insert, update on	MucTieu to Manager

--thủ tục
grant execute on MODIF_DS_ND to Manager 
grant execute on INS_DS_ND to Manager
grant execute on DEL_DS_ND to Manager 

--CẤP QUYỀN ROLE EMPLOYEE
--bảng 
grant select, insert, update, delete on NguoiDung to Employee
grant select on DuLieuSK to Employee 
grant select, insert, update on BaiTap to Employee
grant select, insert, update on BT_ND to Employee 
grant select, insert, update on	MucTieu to Employee

--thủ tục
grant execute on MODIF_DS_ND to Employee 
grant execute on INS_DS_ND to Employee
grant execute on DEL_DS_ND to Employee 

--CẤP QUYỀN ROLE USER
--bảng
grant select, insert, update on NguoiDung to Employee
grant select on DuLieuSK to Employee 
grant select, insert, update on BaiTap to Employee
grant select, insert, update on BT_ND to Employee 
grant select, insert, update on	MucTieu to Employee

--thủ tục
grant execute on MODIF_DS_ND to User_role
grant execute on INS_DS_SK to User_role

--function
grant execute on TinhCaloCan to User_role
grant execute on TinhThoiGianTap to User_role


--View thông tin chi tiết người dùng: View này sẽ hiển thị thông tin chi tiết của mỗi người dùng bao gồm tên đăng nhập, email, ngày sinh và giới tính.

CREATE VIEW ThongTinNguoiDung AS
SELECT MaND, TenND, Email, NgaySinh, GT
FROM NguoiDung;

select * from ThongTinNguoiDung

--View tóm tắt tập luyện của người dùng: View này sẽ tóm tắt tổng số calo mà mỗi người dùng đã đốt cháy từ các bài tập.

CREATE VIEW TomTatTapLuyenNguoiDung AS
SELECT 
    nd.MaND, 
    nd.TenND, 
    SUM(btn.CaloTH) AS TongCaloDotChay
FROM 
    NguoiDung nd
JOIN 
    BT_ND btn ON nd.MaND = btn.MaND
GROUP BY 
    nd.MaND, nd.TenND;

select * from TomTatTapLuyenNguoiDung

--View theo dõi mục tiêu: View này sẽ hiển thị các mục tiêu của mỗi người dùng, thời hạn và trạng thái đạt được.

CREATE VIEW TheoDoiMucTieu AS
SELECT 
    mt.MaND, 
    nd.TenND, 
    mt.TenMT, 
    mt.ThoiHan, 
    mt.DatDuoc
FROM 
    MucTieu mt
JOIN 
    NguoiDung nd ON mt.MaND = nd.MaND;

select * from TheoDoiMucTieu
