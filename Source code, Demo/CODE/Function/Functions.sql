
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

select * from NguoiDung nd, MucTieu mt, DuLieuSK sk
where nd.MaND = mt.MaND and sk.MaND = nd.MaND


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
