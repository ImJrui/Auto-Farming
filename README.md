一款自动农业模组，集成自动种植（Auto Plant）和自动照料（Auto Farm）两大功能。基于营养平衡数学算法，自动规划最优种植组合，种植完成后无缝切换至自动照料模式，覆盖完整的农场自动化流程。

[h3]热键[/h3]
按配置的热键（默认 O 键）打开组合选择界面或关闭所有功能。

[h3]🌿 自动种植（Auto Plant）[/h3]
[b]模式：[/b]关闭 / 开启
点击后打开种植组合（3x3 / 六边形）。

功能：
- 自动筛选当前季节可种植的组合，优先显示季节优先级最高的方案
- 平衡组合算法根据作物营养消耗自动计算最优种植组合，保证土壤养分平衡
- 自动种植 2 块或 4 块农田（需有足够种子）
- 自动锄地与播种（沃姆伍德无需锄地）
- 自动适配 Geometric Placement 模组的坐标吸附逻辑
- 连续 5 秒无有效目标时自动停止，切换至 Auto Farm

注意：
- 请确保种植点没有被杂物阻挡
- 使用列队行为学时，请按热键关闭后再使用本功能

[h3]🌾 自动照料（Auto Farm）[/h3]
[b]模式：[/b]关闭 / 开启

功能：
- 湿度低于 50% 自动浇水
- 养分低于设定值自动施肥，优先使用复合肥
- 自动清理田地中的杂草和碎石
- 作物需要对话时自动开启唱片机
- 超出唱片机范围自动对话鼓励生长

[h3]交互流程[/h3]
1. 按热键打开组合选择弹窗
2. 选择一个平衡组合并确认，进入种植规模确认
3. 选择种植规模（2 格 / 4 格），开始自动种植
4. 所有目标种植完成后，自动切换至自动照料
5. 再次按热键：关闭所有功能（弹窗也会关闭）
6. 按热键再次打开弹窗，选择"继续"：
   - 有待完成的种植目标 → 继续自动种植
   - 无待完成目标 → 直接开启自动照料

[h3]Hotkey[/h3]
Press configured hotkey (default O) to open combo selection or disable all features.

[h3]🌿 Auto Plant[/h3]
[b]Modes:[/b] Off / On
Opens crop layout selection (3x3 or Hex patterns).

Features:
- Automatically filters combos by current season, prioritizing highest seasonal priority
- Balanced combo algorithm calculates optimal planting patterns based on crop nutrient consumption
- Plants 2 or 4 farm tiles automatically if seeds are sufficient
- Automatically tills soil and plants seeds (Wormwood skips tilling)
- Compatible with Geometric Placement mod coordinate snapping
- Automatically stops after 5 seconds with no valid target, switches to Auto Farm

Note:
- Ensure planting spots are not obstructed
- If using Action Queue Reborn, disable it with hotkey before using this feature

[h3]🌾 Auto Farm[/h3]
[b]Modes:[/b] Off / On

Features:
- Waters soil below 50% moisture
- Fertilizes soil below threshold, prioritizing multi-nutrient fertilizer
- Removes nearby weeds and debris
- Automatically plays Gramophone when crops need talking
- Talks to crops outside Gramophone range to encourage growth

[h3]Usage[/h3]
1. Press hotkey to open combo selection popup
2. Select a balanced combo and confirm, then choose planting scale
3. Choose planting scale (2 or 4 tiles) to start Auto Plant
4. After all targets planted, automatically switches to Auto Farm
5. Press hotkey again: disables all features (popup closes)
6. Press hotkey to reopen popup, press Continue:
   - If unfinished planting targets exist → resumes Auto Plant
   - If no unfinished targets → enables Auto Farm directly
