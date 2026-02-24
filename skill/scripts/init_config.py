#!/usr/bin/env python3
"""
Kuake CLI 配置文件初始化脚本

此脚本用于生成 kuake CLI 所需的配置文件 (config.json)。

使用方法:
    python3 init_config.py

配置文件格式:
    {
        "quark": {
            "access_tokens": ["your_access_token_here"]
        }
    }

获取 access_token 的方法:
    1. 登录夸克网盘网页版 (https://pan.quark.cn)
    2. 打开开发者工具 (F12)
    3. 切换到 Application/Storage 标签
    4. 在 Cookies 中找到 p_uid 的值
    5. 或者在 Network 中找到任意请求的 Cookie，提取 p_uid 值
"""

import json
import os
import sys
from pathlib import Path


def get_access_token():
    """获取用户输入的 access_token"""
    print("\n请输入夸克网盘的 access_token:")
    print("(提示: 登录 https://pan.quark.cn，打开开发者工具(F12)，")
    print("在 Application/Storage → Cookies 中找到 p_uid 值)")
    print()

    token = input("access_token: ").strip()

    if not token:
        print("错误: access_token 不能为空")
        return None

    return token


def get_config_path():
    """获取用户指定的配置文件路径"""
    print("\n配置文件保存路径:")
    print("1. 当前目录 (./config.json)")
    print("2. 用户主目录 (~/.config/kuake/config.json)")
    print("3. 自定义路径")

    choice = input("请选择 [1-3，默认 1]: ").strip()

    if choice == "2":
        home = os.path.expanduser("~")
        config_dir = os.path.join(home, ".config", "kuake")
        os.makedirs(config_dir, exist_ok=True)
        return os.path.join(config_dir, "config.json")
    elif choice == "3":
        custom_path = input("请输入完整路径: ").strip()
        if custom_path:
            # 确保目录存在
            config_dir = os.path.dirname(custom_path)
            if config_dir:
                os.makedirs(config_dir, exist_ok=True)
            return custom_path

    # 默认选项 1
    return "./config.json"


def create_config(token, config_path):
    """创建配置文件"""
    config = {
        "quark": {
            "access_tokens": [token]
        }
    }

    try:
        # 将路径转换为绝对路径
        abs_path = os.path.abspath(config_path)

        with open(abs_path, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2, ensure_ascii=False)

        print(f"\n配置文件已创建: {abs_path}")
        return True

    except Exception as e:
        print(f"\n错误: 创建配置文件失败: {e}")
        return False


def main():
    print("=" * 50)
    print("Kuake CLI 配置文件初始化")
    print("=" * 50)

    # 获取 access_token
    token = get_access_token()
    if not token:
        sys.exit(1)

    # 获取配置文件路径
    config_path = get_config_path()

    # 创建配置文件
    if create_config(token, config_path):
        print("\n配置完成!")
        print("\n你可以使用以下命令测试:")
        print(f"  kuake -c {config_path} user")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
