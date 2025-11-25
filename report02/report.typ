#import "../template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv

#let env = parse_dotenv(read("../.env"))

#show: project.with(
  week: "第2回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 11 月 5 日",
)

#set footnote(numbering: sym.dagger + "1")
#set table(inset: (x: 0.8em, y: 0.6em), stroke: none)
#set table.hline(stroke: 0.6pt)
#set table.vline(stroke: 0.6pt)

== 課題 2-1

Instruction status は SUB.D の結果が出た直後で @t1 のようになる。

#figure(
  table(
    columns: 4,
    align: (auto, auto, auto, auto),
    table.hline(),
    table.header([Instruction], [Issue], [Execute], [Write Result]),
    table.hline(),
    [L.D F6,34(R2)], [x], [x], [x],
    [L.D F2,45(R3)], [x], [x], [x],
    [MUL.D F0,F2,F4], [x], [x], [],
    [SUB.D F8,F2,F6], [x], [x], [x],
    [DIV.D F10,F0,F6], [x], [], [],
    [ADD.D F6,F8,F2], [x], [], [],
    table.hline(),
  ),
  caption: [SUB.D の結果が出た直後の Instruction status],
) <t1>

この時点で、2本目のL.Dが Write Result 済みであるのでそれを受けて MUL.D と SUB.D が開始される。
FADD のレイテンシ 3 で SUB.D が先に完了し、結果を書き戻し中である。

SUB.D 完了直後の Reservation stations は @t2 のようになる。

#figure(
  table(
    columns: 8,
    align: (auto, auto, auto, auto, auto, auto, auto, auto),
    table.hline(),
    table.header([Name], [Busy], [Op], [Vj], [Vk], [Qj], [Qk], [A]),
    table.hline(),
    [Load1], [no],  [],    [], [], [], [], [],
    [Load2], [no],  [],    [], [], [], [], [],
    [Add1],  [no],  [],    [], [], [], [], [],
    [Add2],  [yes], [ADD], [F8], [Mem[45+Regs[R3]]], [], [], [],
    [Add3],  [no],  [],    [], [], [], [], [],
    [Mult1], [yes], [MUL], [Regs[F4]], [Mem[45+Regs[R3]]], [], [], [],
    [Mult2], [yes], [DIV], [Mem[34+Regs[R2]]], [], [], [Mult1], [],
    table.hline(),
  ),
  caption: [SUB.D 完了直後の Reservation stations],
) <t2>

SUB.D 結果反映後の Register status は @t3 のようになる。

#figure(
  table(
    columns: 8,
    align: (auto, auto, auto, auto, auto, auto, auto, auto),
    table.hline(),
    table.header([Field], [F0], [F2], [F4], [F6], [F8], [F10], [F12]),
    table.hline(),
    [Qi], [Mult1], [], [], [Add2], [], [Mult2], [],
    table.hline(),
  ),
  caption: [SUB.D 結果反映後の Register status],
) <t3>

== 課題 2-2

分岐予測ミスのペナルティが性能に与える影響を考える。

前提として、幅1の5段パイプラインを考えると、理想状態では 1 命令あたり 1 サイクルで進むため、理想 CPI は 1 である。
また、分岐命令の出現頻度を $f=0.25$、分岐の追加停止を $s$ サイクル、
予測ありのときはミス時のみ $s$ が発生し、精度は $a=0.90$ とする。

平均 CPI は以下のようになる。
- 予測なし: $"CPI" = 1 + f s$
- 予測あり: $"CPI" = 1 + f (1 - a) s$

スループット IPC は $1/"CPI"$ となる。

=== 予測なしの場合
分岐を見るたびストールする。
分岐は 4 回に 1 回発生するため、そのたびに $s$ がかかる。
平均 CPI は $1 + 0.25 s$ となる。

- $s = 1$ のとき、$"CPI" = 1.25, "IPC" = 0.80$
- $s = 2$ のとき、$"CPI" = 1.50, "IPC" = 2/3 approx 0.667$

$s$ を 1 増やすたびに、体感性能が大きく落ちることがわかる。

=== 予測ありの場合
今度はミス時だけ $s$ がかかる。
平均CPI は $(1 + 0.25 times 0.10 times s = 1 + 0.025 s)$ となる。

- $s = 1$ のとき、$"CPI" = 1.025, "IPC" approx 0.975$
- $s = 2$ のとき、$"CPI" = 1.050, "IPC" approx 0.962$

予測なしのときに比べ、$s$ が増えても穏やかな悪化にとどまる。

=== ストールがスループットをどれだけ落とすか

予測なしでは $s$ に比例して一直線に悪化する。
分岐頻度が 25% なので、設計で $s$ が $1$ ふえるたびに足を強く引っ張られる。

予測ありでは同じ $s$ の増分が「ミス率」という小さな倍率で薄まる。
精度を 95% に上げれば傾きは $0.25 times 0.05 = 0.0125$ まで半減する。

=== より深いパイプラインの場合
パイプラインを深くすると、分岐の判定・ターゲット決定が後段にずれるため、
実効ペナルティが大きくなりやすい。
つまり、$s$ が支配的になる。
