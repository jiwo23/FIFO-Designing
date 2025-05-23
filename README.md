```markdown
# 异步 FIFO (First-In, First-Out) 设计与验证

本工程实现了一个带有独立读写时钟域的异步 FIFO 存储器，支持参数化数据宽度和深度，提供满/空指示信号，并附带功能测试和覆盖率验证平台。

---

## 目录结构

```

├── rtl/
│   └── yibififo.v             # FIFO 设计顶层 Verilog 实现
│
├── tb/
│   ├── tb\_yibififo.v          # 简单功能测试平台（Verilog）
│   └── tb\_fifo\_coverage.sv    # 带覆盖率采样的 SystemVerilog 验证平台
│
├── cov/
│   └── fifo\_cov.ucdb          # Questa/ModelSim 覆盖率数据库
│
└── README.md                  # 本文档

````

---

## 设计概述

- **模块名**：`yibififo`
- **参数化**：
  - `DATA_W`：数据位宽，默认 16。
  - `DEPTH`：FIFO 深度，默认 16K（16384）。
- **接口**：
  - **写侧**  
    - `wr_clk`、`wr_rst_n`：写时钟/复位（低有效）。
    - `wr_en`：写使能，高电平时允许写入 `din`。
    - `din[DATA_W-1:0]`：写入数据信号。
    - `full`：满标志，高电平表示 FIFO 已满。
  - **读侧**  
    - `rd_clk`、`rd_rst_n`：读时钟/复位（低有效）。
    - `rd_en`：读使能，高电平时允许读取 `dout`。
    - `dout[DATA_W-1:0]`：读出数据信号。
    - `empty`：空标志，高电平表示 FIFO 为空。
- **实现细节**：
  - 使用 `$clog2(DEPTH)` 生成二进制与格雷码指针。
  - 两级跨时钟域同步器同步异步指针。
  - 满/空判断：  
    - `full`：比较写指针的下一个格雷码与读指针格雷码反转高两位后的值。  
    - `empty`：比较读指针格雷码与写指针格雷码同步后的值。
  - 纯 Verilog `reg [DATA_W-1:0] ram [0:DEPTH-1]` 实现存储阵列。

---

## 验证平台

### 简易功能测试 (`tb/tb_yibififo.v`)

- **目的**：在同一时钟域下验证 FIFO 的基本读写、满/空标志行为。
- **测试流程**：
  1. 复位释放后，对 FIFO 连续写入若干数据。
  2. 停止写入，开始连续读取并检查 `dout` 与写入序列一致。
  3. 在不同写、读时钟速率下，交替开关 `wr_en`/`rd_en`，检验满/空响应。

### 覆盖率驱动测试 (`tb/tb_fifo_coverage.sv`)

- **目的**：对读写控制信号和边界条件进行 SystemVerilog 覆盖率采样，确保测试用例覆盖率满足要求。
- **配置**：
  - 本平台将 FIFO 深度参数化为 `DEPTH = 64`，便于快速仿真。
  - 定义了四大场景任务：
    1. 随机写直到满、随机读直到空，采样 `full`/`empty` 情况。
    2. 2000 组随机读写比组合，采样各控制信号切换分布。
    3. 写满后再写、读空后再读，检验错误使能下的信号状态。
    4. 边界条件下的“empty_hit”、`full_hit` 采样。
- **脚本**：使用 `cg_fifo` coverage group 自动采样。

---

## 仿真与覆盖率收集

以下示例以 **ModelSim/QuestaSim** 为例；在 **Synopsys VCS** 下命令略有差异。

1. **编译 RTL & 功能 Testbench**  
   ```bash
   # 进入项目根目录
   vlog rtl/yibififo.v tb/tb_yibififo.v
````

2. **运行功能仿真**

   ```bash
   vsim -c tb_yibififo -do "run -all; exit"
   ```

3. **编译带覆盖率 Testbench**

   ```bash
   vlog +cover=all rtl/yibififo.v tb/tb_fifo_coverage.sv
   ```

4. **运行覆盖率仿真并生成 UCDB**

   ```bash
   vsim -c -coverage tb_fifo_coverage \
        -do "run -all; coverage save -onexit cov/fifo_cov.ucdb; exit"
   ```

5. **查看覆盖率报告**

   ```bash
   coverage report -details cov/fifo_cov.ucdb
   ```

---

## 关键测试用例

| 用例编号 | 名称                           | 目标                      |
| ---- | ---------------------------- | ----------------------- |
| 1    | 随机写满／随机读空                    | 验证 `full`/`empty` 标志准确性 |
| 2    | 2000 组随机读写比例                 | 验证读写混合场景下控制信号切换覆盖       |
| 3    | 写满后再写／读空后再读                  | 验证对错误使能情况的防护            |
| 4    | 边界条件——`empty_hit`／`full_hit` | 验证边界状态下的标志瞬态            |

---

## 未来改进

* **UVM 验证环境**：可基于 UVM 搭建更灵活的事务级测试、约束随机和序列化报告。
* **AXI-Stream / Avalon-ST 接口**：扩展为标准总线协议，提升可复用性。
* **FIFO 深度自适应监测**：动态调整 FIFO 深度并在线报告。

---

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](./LICENSE)（如需开源请自行添加）。
欢迎 Fork、Issue 和 PR！

```
```
