CREATE DATABASE InstagramMarketingDW;
GO

USE InstagramMarketingDW;
GO

CREATE TABLE Staging_Instagram (
    post_id NVARCHAR(50),
    post_date DATE,
    post_hour INT,
    day_of_week NVARCHAR(20),

    media_type NVARCHAR(50),
    content_category NVARCHAR(100),
    traffic_source NVARCHAR(100),

    hashtags_count INT,
    caption_length INT,
    has_call_to_action BIT,

    impressions INT,
    reach INT,

    likes INT,
    comments INT,
    shares INT,
    saves INT,

    engagement_rate FLOAT,
    followers_gained INT,

    account_type NVARCHAR(50),
    follower_count INT,

    performance_bucket_label NVARCHAR(20)
);

--DATA WAREHOUSE
CREATE TABLE DimTime (
    TimeID INT IDENTITY(1,1) PRIMARY KEY,
    FullDate DATE,
    Day INT,
    Month INT,
    Year INT,
    DayOfWeek NVARCHAR(20),
    Hour INT
);

CREATE TABLE DimContent (
    ContentID INT IDENTITY(1,1) PRIMARY KEY,
    media_type NVARCHAR(50),
    content_category NVARCHAR(100),
    hashtags_count INT,
    caption_length INT,
    has_call_to_action BIT
);

CREATE TABLE DimTraffic (
    TrafficID INT IDENTITY(1,1) PRIMARY KEY,
    traffic_source NVARCHAR(100)
);

CREATE TABLE DimAccount (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    account_type NVARCHAR(50),
    follower_count INT
);

CREATE TABLE FactInstagram (
    FactID INT IDENTITY(1,1) PRIMARY KEY,

    TimeID INT,
    ContentID INT,
    TrafficID INT,
    AccountID INT,

    impressions INT,
    reach INT,
    likes INT,
    comments INT,
    shares INT,
    saves INT,

    engagement_rate FLOAT,
    followers_gained INT,

    performance_bucket_label NVARCHAR(20),

    FOREIGN KEY (TimeID) REFERENCES DimTime(TimeID),
    FOREIGN KEY (ContentID) REFERENCES DimContent(ContentID),
    FOREIGN KEY (TrafficID) REFERENCES DimTraffic(TrafficID),
    FOREIGN KEY (AccountID) REFERENCES DimAccount(AccountID)
);

--LOAD DIMENSION TABLES
--DimTime
INSERT INTO DimTime (FullDate, Day, Month, Year, DayOfWeek, Hour)
SELECT DISTINCT
    post_date,
    DAY(post_date),
    MONTH(post_date),
    YEAR(post_date),
    day_of_week,
    post_hour
FROM Staging_Instagram;

--DimContent
INSERT INTO DimContent (media_type, content_category, hashtags_count, caption_length, has_call_to_action)
SELECT DISTINCT
    media_type,
    content_category,
    hashtags_count,
    caption_length,
    has_call_to_action
FROM Staging_Instagram;

--DimTraffic
INSERT INTO DimTraffic (traffic_source)
SELECT DISTINCT traffic_source
FROM Staging_Instagram;

--DimAccount
INSERT INTO DimAccount (account_type, follower_count)
SELECT DISTINCT account_type, follower_count
FROM Staging_Instagram;

--FactInstagram
INSERT INTO FactInstagram (
    TimeID, ContentID, TrafficID, AccountID,
    impressions, reach, likes, comments, shares, saves,
    engagement_rate, followers_gained, performance_bucket_label
)
SELECT
    t.TimeID,
    c.ContentID,
    tr.TrafficID,
    a.AccountID,

    s.impressions,
    s.reach,
    s.likes,
    s.comments,
    s.shares,
    s.saves,

    s.engagement_rate,
    s.followers_gained,
    s.performance_bucket_label

FROM Staging_Instagram s
JOIN DimTime t 
    ON s.post_date = t.FullDate AND s.post_hour = t.Hour

JOIN DimContent c 
    ON s.media_type = c.media_type 
    AND s.content_category = c.content_category

JOIN DimTraffic tr 
    ON s.traffic_source = tr.traffic_source

JOIN DimAccount a 
    ON s.account_type = a.account_type;

--Add engagement
ALTER TABLE FactInstagram
ADD engagement INT;

UPDATE FactInstagram
SET engagement = likes + comments + shares + saves;