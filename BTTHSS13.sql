CREATE DATABASE IF NOT EXISTS botro_session13_practice;
USE botro_session13_practice;

-- Bảng 1: Lưu trữ thông tin sản phẩm
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL
);

-- Bảng 2: Ghi log lịch sử thay đổi của kho hàng
CREATE TABLE inventory_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(20) NOT NULL,  -- Phân loại: 'INSERT', 'UPDATE', 'DELETE', 'WARNING'
    log_message VARCHAR(255) NOT NULL, -- Chi tiết nội dung log
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Bài 1: Trigger BEFORE INSERT - Chuẩn hóa và kiểm duyệt dữ liệu thêm mới 
-- Viết một trigger có tên before_product_insert hoạt động trước khi thêm một sản phẩm mới vào bảng products:
-- Yêu cầu 1: Tên sản phẩm (product_name) phải được xóa bỏ các khoảng trắng thừa ở hai đầu. (trim())
-- Yêu cầu 2: Nếu người dùng nhập số lượng (quantity) < 0, hãy tự động gán lại quantity = 0. (set)
-- Yêu cầu 3: Nếu giá bán (price) được nhập vào < 0, hãy chặn tiến trình thêm mới và báo lỗi với thông báo: "Giá sản phẩm không được nhỏ hơn 0". (signal sqlstate ‘45000’)

DELIMITER //
create trigger before_product_insert  
before insert on products 
for each row 
BEGIN 
	
    set new.product_name = trim(new.product_name);
    
    if new.quantity < 0 then 
    set new.quantity = 0; 
    end if;
    
    if new.price < 0 then 
    signal sqlstate '45000'
    set message_text = 'Giá sản phẩm không được nhỏ hơn 0';
    
    end if ;
END//
DELIMITER ;
drop trigger before_product_insert  ;
-- Test case cho câu 1 nhập tên cách 
insert into products (product_name,price,quantity)
values 
('    Trà sữa',10000,10);
-- Test case thop giá nhỏ hơn 0 
insert into products (product_name,price,quantity)
values 
('Trà sữa',-10000,10);
-- Test case thop số lượng âm 
insert into products (product_name,price,quantity)
values 
('Trà chanh',10000,-10);
-- Test case trường hợp 3 cái cùng sai 
insert into products (product_name,price,quantity)
values 
('    Trà sữa',-10000,-10);
select * from products ;

-- Bài 2: Trigger AFTER INSERT - Ghi log thêm mới sản phẩm 
-- Viết một trigger có tên after_product_insert hoạt động sau khi một sản phẩm được thêm thành công:
-- Yêu cầu: Tự động chèn một dòng vào bảng inventory_logs với action_type là 'INSERT' và log_message có định dạng: "Đã thêm mới sản phẩm: [Tên sản phẩm] với số lượng ban đầu là [Số lượng]".

DELIMITER //

create trigger after_product_insert 

after insert on products 

for each row 

BEGIN 
	INSERT INTO inventory_logs  (action_type, log_message )
    VALUES
('INSERT', CONCAT(' Đã thêm mới sản phẩm: ', new.product_name));
END//

DELIMITER ;

-- Test câu 2 
insert into products (product_name,price,quantity)
values 
('Trà hoa cúc ',10000,10);
select * from inventory_logs;

-- Bài 3: Trigger BEFORE UPDATE - Ngăn chặn cập nhật sai lệch giá quá lớn 
-- Để tránh nhân viên gõ nhầm giá (ví dụ: từ 10.000 thành 100.000), viết trigger before_product_update:
-- Yêu cầu: Trước khi cập nhật sản phẩm, hãy kiểm tra giá mới (NEW.price). Nếu giá mới cao hơn gấp đôi giá cũ (OLD.price),
--  hãy chặn tiến trình cập nhật và báo lỗi với thông báo: "Mức giá mới tăng bất thường, vui lòng kiểm tra lại!".

DELIMITER //

create trigger before_product_update

before update on products 

for each row 

BEGIN 
	if new.price > old.price*2  then 
    signal sqlstate '45000'
    set message_text= 'Mức giá mới tăng bất thường, vui lòng kiểm tra lại' ;
    end if ;
END // 
drop trigger before_product_update
DELIMITER ;

-- Test câu 3 thop sai 

update products 
set price = price*3
where product_id = 2;

-- Test câu 3 thop đúng 
update products 
set price = price*1.5
where product_id = 2;