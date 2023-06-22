# Creating Schemas :-
drop table if exists Product;
CREATE table Product(Product_id integer, Product_name text, Price integer);
INSERT INTO Product(Product_id, Product_name, Price) VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);
SELECT * FROM Product;

drop table if exists Users;
CREATE table Users(Userid integer, Signup_date date);
INSERT INTO Users(Userid, Signup_date) VALUES
(1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');
SELECT * FROM Users;

drop table if exists Sales;
CREATE TABLE Sales(Userid integer,Created_date date,Product_id integer); 
INSERT INTO Sales(Userid,Created_date,Product_id) VALUES 
(1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);
SELECT * FROM Sales;

drop table if exists Goldusers_signup;
CREATE TABLE Goldusers_signup(Userid integer,Gold_signup_date date); 
INSERT INTO Goldusers_signup(Userid,Gold_signup_date) VALUES 
(1,'2017-09-22'),
(3,'2017-04-21');
SELECT * FROM Goldusers_signup;


# QUERIES :-

# Q1 - What is total amount each customer spent on Swiggy ?
SELECT s.userid, SUM(p.Price) as Total_Amount FROM 
Sales s INNER JOIN Product p
on s.product_id = p.product_id
group by s.userid;


# Q2 - How many days has each customer visited Swiggy ?
SELECT userid, count(distinct created_date) as Total_days FROM Sales
group by userid;


# Q3 - What was the first product purchased by each customer ?
SELECT * FROM
(SELECT *, rank() over(partition by userid order by created_date) as rnk FROM Sales) a WHERE rnk=1;


# Q4 - What is the most purchased item on the menu and how many times it has been purchased by all the customers ?
Select userid, count(product_id) as No_of_times FROM Sales WHERE
product_id = (SELECT product_id FROM Sales group by product_id order by count(product_id) desc limit 1) 
group by userid;

# Q5 - Which item is the most popular(Favourite) of each customer ?
SELECT * FROM 
(SELECT *, rank() over(partition by userid order by cnt desc) rnk FROM
(SELECT userid, product_id, count(product_id) cnt FROM Sales group by product_id,userid)a)b
WHERE rnk = 1;


# Q6 - Which item was purchased by the customer after they became the gold member ?
SELECT userid, product_id, created_date FROM
(SELECT a.*, rank() over(partition by userid order by created_date asc) rnk FROM
(Select a.userid,a.created_date,a.product_id,b.gold_signup_date from Sales a INNER JOIN goldusers_signup b 
on a.userid = b.userid and a.created_date>=b.Gold_signup_date) a) b
WHERE rnk = 1;


# Q7 - Which item was purchased by the customer just before they became gold member ? 
SELECT userid,product_id,created_date FROM
(SELECT a.*,rank() over(partition by userid order by created_date desc) rnk FROM
(SELECT a.userid,a.product_id,a.created_date,b.gold_signup_date FROM Sales a INNER JOIN goldusers_signup b 
on a.userid = b.userid and created_date<Gold_signup_date) a) b
WHERE rnk = 1;

# Q8 - What is the total no. of orders and total amount spent by the customer just before they became gold member ? 
SELECT userid, count(created_date) TotaL_Orders, sum(price) Total_Amount_Spent FROM
(SELECT c.*, d.price FROM
(SELECT a.userid,a.product_id,a.created_date,b.gold_signup_date FROM Sales a INNER JOIN goldusers_signup b 
on a.userid = b.userid and created_date<Gold_signup_date) c INNER JOIN Product d on c.product_id = d.product_id) e
group by userid;



# Q9 - If buying each product generates points for ex: 5Rs = 2 Swiggy points and each product has different purchasing points for ex: for p1 5Rs = 1 Swiggy point, for p2 10Rs = 5 Swiggy point and p3 5Rs = 1 Swiggy point, 2Rs = 1 Swiggy point,                                                             calculate 1.points collected by each customer and 2.for which product most points have been given till now. 
# 1.total points by customers
SELECT userid, sum(total_points) as Total_points_earned FROM
(SELECT e.*,amt/points as total_points FROM
(SELECT d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points FROM
(SELECT c.userid, c.product_id, sum(price) amt FROM
(SELECT a.*, b.price FROM Sales a INNER JOIN Product b on a.product_id=b.product_id)c 
group by userid,product_id order by userid,product_id)d)e)f
group by userid;

# 2. product with most points
SELECT h.* FROM
(SELECT g.*,rank() over(order by Total_points_earned desc) rnk FROM
(SELECT product_id, sum(total_points) as Total_points_earned FROM
(SELECT e.*,amt/points as total_points FROM
(SELECT d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points FROM
(SELECT c.userid, c.product_id, sum(price) amt FROM
(SELECT a.*, b.price FROM Sales a INNER JOIN Product b on a.product_id=b.product_id)c 
group by userid,product_id order by userid,product_id)d)e)f
group by product_id)g)h
where rnk=1;



# Q10 - In the first year after a customer joins the gold program (including the join date ) irrespective of what customer has purchased earn 5 Swiggy points for every 10Rs spent. Who earned more 1 or 3 what was their points earning in first year ? 1sp = 2Rs 
SELECT c.*,d.price/2 as Total_points_earned FROM
(SELECT a.userid,a.product_id,a.created_date,b.gold_signup_date FROM Sales a INNER JOIN goldusers_signup b on a.userid=b.userid AND created_date>=Gold_signup_date and a.created_date<=DATE_ADD(Gold_signup_date, INTERVAL 1 YEAR))c INNER JOIN product d on c.product_id = d.Product_id;


# Q11 - Rank all transaction of the customers.
SELECT *,rank() over(partition by userid order by created_date) rnk from Sales;

# Q12 - Rank all transaction for each member whenever they are Swiggy gold member for every non gold member transaction mark as NA.
SELECT d.*, case when rnk=0 then 'na' else rnk end as rnkk FROM 
(SELECT c.*, cast((case when gold_signup_date is null then 0 else rank()over(partition by userid order by created_date desc) end) as char(2)) as rnk FROM
(SELECT a.userid,a.product_id,a.created_date,b.gold_signup_date FROM Sales a LEFT JOIN Goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date)c)d;