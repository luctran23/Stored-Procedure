USE master
GO
IF (EXISTS(SELECT * FROM sys.sysdatabases WHERE name='QLBanHang'))
DROP DATABASE QLBanHang
go
create database QLBanHang;
GO

USE QLBanHang
GO
create table PXUAT(
	SoPx char(4) PRIMARY KEY,
	NgayXuat Date default getDate(),
	TenKh nvarchar(100) not null,
	)
GO

create table VATTU(
	MaVTu char(4) PRIMARY KEY,
	TenVTu nvarchar(100) not null,
	DvTinh nvarchar(10) not null,
	PhanTram Real,
	)
GO

create table CTPXUAT(
	SoPx char(4),
	CONSTRAINT FK_SoPx FOREIGN KEY(SoPx) REFERENCES PXUAT(SoPx),
	MaVTu char(4),
	CONSTRAINT FK_MaVTu FOREIGN KEY(MaVTu) REFERENCES VATTU(MaVTu), 
	SlXuat int not null,
	DgXuat Money not null,
	PRIMARY KEY(SoPx, MaVTu),
)
GO

create table TONKHO(
	NamThang char(6),
	MaVTu char(4),
	CONSTRAINT FK_MaVTu_TONKHO FOREIGN KEY(MaVTu) REFERENCES VATTU(MaVTu),
	SLDau int not null,
	TongSLN int not null,
	TongSLX int not null,
	SLCuoi int not null,
	PRIMARY KEY(NamThang, MaVTu),
	)
GO

Create table NHACC(
		MaNhaCc char(3) PRIMARY KEY,
		TenNhaCc nvarchar(100) not null,
		DiaChi nvarchar(200) not null,
		DienThoai varchar(20) not null
	)
GO

create table DONDH(
	SoDh char(4) primary key,
	NgayDh datetime,
	MaNhaCc char(3),
	CONSTRAINT FK_MaNhaCc_DONDH FOREIGN KEY(MaNhaCc) REFERENCES NHACC(MaNhaCc),
)
GO

Create table CTDONDH(
	SoDh char(4),
	MaVTu char(4),
	SlDat int not null,
	PRIMARY KEY (SoDH,MaVTu),
	CONSTRAINT FK_SoDh_CTDONDH FOREIGN KEY(SoDh) REFERENCES DONDH(SoDh),
	CONSTRAINT FK_MaVTu_CTDONDH FOREIGN KEY(MaVTu) REFERENCES VATTU(MaVTu),
	)
GO

Create table PNHAP(
	SoPn char(4) primary key,
	NgayNhap datetime,
	SoDh char(4),
	CONSTRAINT FK_SoDh_PNHAP FOREIGN KEY(SoDh) REFERENCES DONDH(SoDh),
)
GO

Create table CTPNHAP(
	SoPn char(4),
	MaVTu char(4),
	SlNhap int not null,
	DgNhap Money not null,
	PRIMARY KEY(SoPN, MaVTu),
	CONSTRAINT FK_SoPn_CTPNHAP FOREIGN KEY(SoPn) REFERENCES PNHAP(SoPn),
	CONSTRAINT FK_MaVTu_CTPNHAP FOREIGN KEY(MaVTu) REFERENCES VATTU(MaVTu),
)

select SlDat from CTDONDH where SoDh = 'D001' and MaVTu = 'DD01';

--1.1a Xay dung thu tuc tinh so  luong dat hang voi tham so dau vao là: @SoDh, @MaVTu va output la: @SlDat

create proc spud_DONDH_TinhSLDat ( @SoDh char(4), @MaVTu char(4), @SlDat int output)
as
begin
	select @SlDat = SlDat from CTDONDH where SoDh = @SoDh and MaVTu = @MaVTu
end
declare @kq int
exec spud_DONDH_TinhSLDat 'D001', 'DD01', @kq out
print 'So luong dat cua mat hang nay la: ' + cast(@kq as char(4))


--1.1b. Tinh tong so luong da nhap 
select * from CTPNHAP
select * from PNHAP
create proc spud_PNHAP_TinhTongSLNHang (@SoDh char(4), @MaVTu char(4), @SlNhap int output)
as
begin
	select @SlNhap = sum(SlNhap) from PNHAP inner join CTPNHAP on PNHAP.SoPn = CTPNHAP.SoPn
	where SoDh = @SoDh and MaVTu = @MaVTu 
end
declare @kq int
exec spud_PNHAP_TinhTongSLNHang  'D001', 'DD01', @kq out
print 'Tong so luong nhap cua mat hang nay trong don dh la: ' + cast( @kq as char(4) )

--1.1c. Tinh so luong ton kho cuoi ki
select * from TONKHO
create proc spud_TONKHO_TinhTonCuoi ( @NamThang char(6), @MaVTu char(4), @SlTon int output)
as 
begin
	select @SlTon = SLCuoi from TONKHO where NamThang = @NamThang and MaVTu = @MaVTu
end

declare @kq int
exec spud_TONKHO_TinhTonCuoi '200501', 'DD01', @kq out
print 'Tong so luong ton kho cua vat tu nay la: ' + cast( @kq as char(5) )

--1.2a Xay dung thu tuc them moi du lieu
select * from VATTU
create proc spud_VATTU_Them ( @MaVTu char(4), @TenVTu nvarchar(100), @DvTinh nvarchar(10), @PhanTram Real )
as
begin
	if(exists (select * from VATTU where MaVTu = @MaVTu) )
		begin
			print ' MaVTu is already existed in VATTU table'
			return
		end
	else 
		insert into	VATTU values ( @MaVTu, @TenVTu, @DvTinh, @PhanTram )
end
exec spud_VATTU_Them 'DD10', 'spara shoes', 'chiec', 23

--1.2b. Thu tuc xoa 1 vat tu voi rang buoc cho san
alter proc spud_VATTU_Xoa ( @MaVTu char(4) )
as 
begin
	if( exists  (select * from CTDONDH where MaVTu = @MaVTu) and exists  (select * from CTPXUAT where MaVTu = @MaVTu) and 
	 exists (select * from TONKHO where MaVTu = @MaVTu) )
		begin
			print 'MaVTu is already existed in CTDONDH or CTPXUAT or TONKHO tables'
			return
		end
	else if(not exists (select * from VATTU where MaVTu = @MaVTu))
		begin
			print 'Invalid MaVTu in VaTTu table'
			return
		end
		else
			delete from VATTU where MaVTu = @MaVTu;
end
exec spud_VATTU_Xoa 'DD10'

-- 1.2c Xay dung thu tuc sua doi vat tu
create proc spud_VATTU_Sua ( @MaVTu char(4), @TenVTu nvarchar(100), @DvTinh nvarchar(10), @PhanTram Real )
as
begin
	if(not exists (select * from VATTU where MaVTu = @MaVTu) )
		begin
			print 'Invalid @MaVTu'
			return
		end
	else
		update VATTU
		set MaVTu = @MaVTu, 
			TenVTu = @TenVTu,
			DvTinh = @DvTinh,
			PhanTram = @PhanTram
		where MaVTu = @MaVTu
end
exec spud_VATTU_Sua 'd', 'tom', 'dkf', 100

--1.3a Xay thu tuc liet ke 
alter proc spud_VATTU_BcaoDanhSach
as
	select * from VATTU
	order by TenVTu 

exec spud_VATTU_BcaoDanhSach

--1.3b 

alter proc spud_TONKHO_BcaoTonkho ( @NamThang char(6) )
as
begin
	if( @NamThang not in (select NamThang from TONKHO) )
		begin
			print 'Invalid @NamThang'
			return
		end
	else 
		select TONKHO.*, TenVTu from TONKHO inner join VATTU on TONKHO.MaVTu = VATTU.MaVTu
		where NamThang = @NamThang
end
exec spud_TONKHO_BcaoTonkho 

--1.3c 

select * from PXUAT
alter proc spud_PXUAT_BcaoPxuat @SoPx char(4) = null
as
begin
	if(@SoPx is null)
		begin
			select * from PXUAT
			return
		end
	else if ( exists (select * from PXUAT inner join CTPXUAT on PXUAT.SoPx = CTPXUAT.SoPx
					  inner join VATTU on CTPXUAT.MaVTu = VATTU.MaVTu where PXUAT.SoPx = null) )
		begin
			print 'SoPx cannot be null'
			return
		end
	else 
		select PXUAT.*, CTPXUAT.*, TenVTu from PXUAT inner join CTPXUAT on PXUAT.SoPx = CTPXUAT.SoPx
					  inner join VATTU on CTPXUAT.MaVTu = VATTU.MaVTu where PXUAT.SoPx = @SoPx
end

exec spud_PXUAT_BcaoPxuat 'X001'

--1.4a
select * from DONDH
select * from NHACC
alter proc spud_DONDH_Them ( @SoDh char(4), @MaNhaCc char(3), @NgayDh datetime = null )
as
begin
	if( exists (select * from DONDH where SoDh = @SoDh) or not exists (select * from NHACC where MaNhaCc = @MaNhaCc) )
		begin
			print 'Invalid MaNhaCc'
			return
		end
	else if( @NgayDh is null )
		insert into DONDH values ( @SoDh, getdate(), @MaNhaCc )
	else 
		insert into DONDH values ( @SoDh, @NgayDh, @MaNhaCc )
end
exec spud_DONDH_Them 'D007','C04'

--1.4b thu tuc xoa trong bang DONDH
select * from CTDONDH;
select * from DONDH
select * from PNHAP

alter proc spud_DONDH_Xoa ( @SoDh char(4) )
as
begin
	if(exists (select * from PNHAP where SoDh = @SoDh) or not exists (select * from DONDH where SoDh = @SoDh ) )
		begin
			print 'Invalid SoDh'
			return
		end
	else 
		begin
			delete from DONDH where SoDh = @SoDh
			if(not exists (select * from CTDONDH where SoDh = @SoDh) )
				return
			else
				delete from CTDONDH where SoDh = @SoDh
		end
end

exec spud_DONDH_Xoa '1'

--1.4c	xay dung thu tuc sua doi

alter proc spud_DONDH_Sua (  @SoDh char(4), @NgayDh datetime, @MaNhaCc char(3) )
as
begin
	if( not exists (select * from NHACC where MaNhaCc = @MaNhaCc) or not exists (select * from PNHAP where SoDh = @SoDh) 
	or exists (select * from PNHAP where NgayNhap <= @NgayDh) )
		begin
			print 'Invalid MaNhaCc or SoDh or NgayDh'
			return
		end
	else 
		update DONDH
		set SoDh = @SoDh,
			NgayDh = @NgayDh,
			MaNhaCc = @MaNhaCc
		where SoDh = @SoDh
end

exec spud_DONDH_Sua 'D001', '2000-01-01', 'C01'

