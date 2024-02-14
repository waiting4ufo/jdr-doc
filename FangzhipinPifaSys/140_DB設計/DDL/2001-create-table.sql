-- テーブル作成文
-- 数据表生成文

-- a

-- ■「ユーザ管理」t_user >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CREATE TABLE `huiling`.`t_user` (
  `company_id` VARCHAR(6) NOT NULL COMMENT '会社番号',
  `login_id` VARCHAR(20) NOT NULL COMMENT 'ログインID',
  `pwd` VARCHAR(20) NOT NULL COMMENT 'パスワード',
  `account_lock_flg` TINYINT NOT NULL DEFAULT 0 COMMENT 'ロックフラグ',
  `employee_id` VARCHAR(6) NOT NULL COMMENT '社員番号',
  `name` VARCHAR(50) NOT NULL COMMENT '名前',
  `sex` TINYINT NOT NULL DEFAULT 1 COMMENT '性別',
  `join_date` DATETIME NOT NULL COMMENT '入社年月日',
  `birthday` DATETIME NOT NULL COMMENT '誕生日',
  `contact` VARCHAR(100) NULL COMMENT '連絡方法',
  `address` VARCHAR(100) NULL COMMENT '郵便番号',
  `post_code` VARCHAR(10) NULL COMMENT '郵便番号',
  `level` TINYINT NOT NULL DEFAULT 0 COMMENT 'レベル',
  `retirement_date` DATETIME NULL COMMENT '退職年月日',
  `last_login` DATETIME NULL COMMENT '最終ログイン時刻',
  `registered_date` DATETIME NOT NULL,
  `registered_employee_id` VARCHAR(6) NOT NULL,
  `update_date` DATETIME NOT NULL,
  `update_employee_id` VARCHAR(6) NOT NULL,
  PRIMARY KEY (`company_id`, `employee_id`),
  UNIQUE INDEX `login_id_UNIQUE` (`login_id` ASC) VISIBLE)
-- ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = 'ユーザの基本情報を管理';

-- 日付default: CURRENT_TIMESTAMP
ALTER TABLE `huiling`.`t_user` 
CHANGE COLUMN `registered_date` `registered_date` DATETIME NOT NULL DEFAULT now() ,
CHANGE COLUMN `update_date` `update_date` DATETIME NOT NULL DEFAULT now() ;
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





