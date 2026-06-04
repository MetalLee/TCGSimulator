# TCGSimulator MVP

TCGSimulator 是一个 Godot 4 Web 端 MVP，目标是验证轻量级挂机卡牌收集与摆摊交易循环。当前版本使用 GDScript、本地 JSON 数据和 `user://save_game.json` 存档，经济系统完全由本地模拟服务驱动。

## 项目简介

核心循环：

1. 通过挂机时间领取 `basic_pack` 和金币。
2. 打开卡包获得卡牌。
3. 新卡进入图鉴，重复卡进入库存。
4. 将卡牌上架到自己的摊位。
5. 使用 NPC 访客模拟售出卡牌。
6. 用金币购买更多卡包，或在模拟市场购买缺失卡牌。

当前实现包含仪表盘、卡包、图鉴、库存、我的摊位、市场、Debug、新手引导、目标奖励、本地保存读取、NPC 买家和模拟市场。

## 如何在 Godot 中运行

1. 使用 Godot 4.x 打开项目根目录。
2. 确认主场景为 `res://scenes/Main.tscn`。
3. 点击运行项目。

项目只使用 GDScript，不依赖 C# 或外部插件。运行时只读取 `res://data/cards.json` 和 `res://data/packs.json`，玩家进度保存到 `user://save_game.json`。

## 中文字体

Godot Web 端不能依赖浏览器或操作系统一定存在中文字体，否则中文会显示为方框或乱码。项目使用全局 Theme：

- Theme 文件：`theme/main_theme.tres`
- 字体路径：`assets/fonts/SourceHanSansSC-Regular.ttf`
- 默认字号：`18`

如果 `assets/fonts/SourceHanSansSC-Regular.ttf` 不存在，请开发者手动放入 Source Han Sans SC / 思源黑体 Regular 字体文件，并保持该文件名不变，然后重新打开 Godot 让资源导入，再重新导出 Web。

`data/cards.json` 和 `data/packs.json` 使用 UTF-8 文本保存。不要在代码中手动进行 GBK、ANSI 或其他本地编码转换。

## 如何测试 MVP 核心循环

1. 首次进入后阅读新手引导。
2. 在仪表盘查看新手目标和当前挂机奖励。
3. 使用 Debug 页的“快进 1 小时”或“快进 8 小时”制造挂机时间。
4. 回到仪表盘领取挂机奖励。
5. 进入卡包页打开 `basic_pack`。
6. 在库存页或我的摊位页上架卡牌。
7. 在我的摊位页点击“模拟访客”，观察交易记录和金币变化。
8. 在市场页筛选未收集卡牌并购买。
9. 使用 Debug 页保存、读取、重置来验证本地存档。

## 如何导出 Web

1. 在 Godot 中安装对应版本的 Web export templates。
2. 打开 `Project > Export`。
3. 选择 `Web` preset。
4. 导出到 `exports/web/index.html`。
5. 使用本地静态服务器托管 `exports/web/` 目录。

## 如何本地托管 Web 导出

项目包含一个无外部依赖的 Node.js 静态服务器：

```bash
npm run serve:web
```

默认地址是 `http://127.0.0.1:8787/`，默认托管目录是 `exports/web/`。如需换端口：

```bash
PORT=9000 npm run serve:web
```

在 Windows PowerShell 中可以使用：

```powershell
$env:PORT = "9000"; npm run serve:web
```

注意：Web 构建需要通过 HTTP 服务访问，不建议直接双击打开 HTML 文件。Godot Web 导出使用浏览器存储映射 `user://`，不同浏览器、域名或隐私模式可能对应不同存档空间。

## 已知限制

- 当前没有真实后端、登录、多人交易或支付系统。
- 卡牌与卡包数据来自本地 JSON。
- 市场和买家都是本地模拟，不代表真实玩家。
- 存档只保存在当前浏览器环境对应的 `user://` 空间。
- 没有复杂美术、动画、战斗、组卡或排行榜。
- Web 导出前需要本机安装 Godot Web export templates。

## 未来后端计划

后续可以将当前 Autoload 服务逐步替换为 HTTP API：

- `CardDatabase` 从后端拉取卡牌、卡包、系列和稀有度配置。
- `GameState` 由账号系统绑定云端玩家状态。
- `SaveService` 改为保存到后端，并保留本地缓存。
- `MarketService` 改为真实玩家上架与购买接口。
- `EconomyService` 将挂机奖励、开包和交易税计算交由后端校验。

当前代码把数据、经济、市场和存档逻辑拆在独立 Autoload 中，目的是让本地 MVP 能在以后较低成本迁移到后端服务。
