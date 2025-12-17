#import "../template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/timeliney:0.4.0"

#let env = parse_dotenv(read("../.env"))

#show: project.with(
  week: "第4回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 12 月 17 日",
)

#set footnote(numbering: sym.dagger + "1")
#set table(inset: (x: 0.8em, y: 0.6em), stroke: none)
#set table.hline(stroke: 0.6pt)
#set table.vline(stroke: 0.6pt)

#show ref: it => {
  "["
  it
  "]"
}

スライド及び課題文よりパラメータとして、以下のパラメータを使用する

- DLXV のスタートアップペナルティ
  - ベクトル加算 = $6$ サイクル
  - ベクトル乗算 = $7$ サイクル
  - ベクトル除算 = $20$ サイクル
  - ベクトル・ロード = $12$ サイクル
- $"MVL" = 64$
- $T_"element" = 3$
- $T_"loop" = 18$
- $T_"base" = 10$

== ADDV と SV もチェイニングできるとした場合の $R_infinity$

元のケースでは、ADDV と SV がチェイニングできず、間に 4 サイクルのストールがあった。
これを。「チェイニングできる」に変えると、SV は ADDV 完了待ちをしなくてよくなり、LV (V2) が終わってパイプが空く時刻が下限になる。

p.6 の表を参考に、新しい 1 ベクトルのタイミングを表にすると @t1 のようになる。

#figure(
  table(
    columns: 4,
    align: (left, left, left, left),
    table.hline(),
    table.header([命令], [], [開始時間], [完了時間]),
    table.hline(),
    [LV]   , [V1, Rx]    , [$1$]         , [$12+64=76$],
    [MULTV], [a, V1]     , [$12+1=13$]   , [$12+7+64=83$],
    [LV]   , [V2, Ry]    , [$76+1=77$]   , [$76+12+64=152$],
    [ADDV] , [V3, V1, V2], [$76+12+1=89$], [$88+6+64=158$],
    [SV]   , [Ry, V3]    , [$152+1=153$] , [$152+12+64=228$],
    table.hline(),
  ),
  caption: [DAXPY on DLXV のタイミング],
) <t1>

#timeliney.timeline(
  show-grid: false,
  tasks-vline: false,
  milestone-line-style: (stroke: (paint: gray, dash: "dashed")),
  {
    import timeliney: *
      
    headerline(([時間], 228))
  
    taskgroup({
      task(
        "LV", 
        (from: 0, to: 12, style: (stroke: 2pt + luma(20%))),
        (from: 12, to: 76, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "MULTV",
        (from: 12, to: 12+7, style: (stroke: 2pt + luma(20%))),
        (from: 12+7, to: 83, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "LV",
        (from: 76, to: 76+12, style: (stroke: 2pt + luma(20%))),
        (from: 76+12, to: 152, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "ADDV",
        (from: 88, to: 88+6, style: (stroke: 2pt + luma(20%))),
        (from: 88+6, to: 158, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "SV",
        (from: 152, to: 152+12, style: (stroke: 2pt + luma(20%))),
        (from: 152+12, to: 228, style: (stroke: 2pt + luma(70%))),
      )
    })

    milestone(at: 0, "")
    milestone(at: 12, "")

    milestone(at: 76, "")
    milestone(at: 94, "")

    milestone(at: 152, "")
    milestone(at: 158, "")
  }
)

以上より、

$
T_"start" = 228 - 64 times T_"element" = 228 - 192 = 36
$

これを性能式に代入すると、

$
T_n
  &= T_"base" + ceil(n / "MVL") times (T_"loop" + T_"start") + n times T_"element" \
  &= 10 + ceil(n / 64) times (18 + 36) + 3 n
$

よって、スライド中の $R_infinity$ の求め方と同様にして、

$
lim_(n -> infinity) T_n / n = 3 + (18 + 36) / 64 = 3.84375
$

よって、スライド中同様に 80MHz を代入することで、

$
R_infinity = (2 times 80) / 3.84375 approx 41.6 "MFLOPS"
$

== lane を導入し、各々のベクトル演算が1/2 の時間で終わると仮定したときの 1 イタレーションの実行時間

Lane 導入により、ベクトル演算の実行時間が 1/2 の時間で終わるということは、$n = 32$ 相当になる。
ロードストアパイプは 1 本のままなため、$n = 64$ 相当のままである。

p.6 の表を参考に、タイミングを表にすると @t2 のようになる。

#figure(
  table(
    columns: 4,
    align: (left, left, left, left),
    table.hline(),
    table.header([命令], [], [開始時間], [完了時間]),
    table.hline(),
    [LV]   , [V1, Rx]    , [$1$]         , [$12+64=76$],
    [MULTV], [a, V1]     , [$12+1=13$]   , [$12+7+64=83$],
    [LV]   , [V2, Ry]    , [$76+1=77$]   , [$76+12+64=152$],
    [ADDV] , [V3, V1, V2], [$76+12+1=89$], [$88+6+32=126$],
    [SV]   , [Ry, V3]    , [$152+1=153$] , [$152+12+64=228$],
    table.hline(),
  ),
  caption: [DAXPY on DLXV のタイミング],
) <t2>

#timeliney.timeline(
  show-grid: false,
  tasks-vline: false,
  milestone-line-style: (stroke: (paint: gray, dash: "dashed")),
  {
    import timeliney: *
      
    headerline(([時間], 228))
  
    taskgroup({
      task(
        "LV", 
        (from: 0, to: 12, style: (stroke: 2pt + luma(20%))),
        (from: 12, to: 76, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "MULTV",
        (from: 12, to: 12+7, style: (stroke: 2pt + luma(20%))),
        (from: 12+7, to: 83, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "LV",
        (from: 76, to: 76+12, style: (stroke: 2pt + luma(20%))),
        (from: 76+12, to: 152, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "ADDV",
        (from: 88, to: 88+6, style: (stroke: 2pt + luma(20%))),
        (from: 88+6, to: 126, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "SV",
        (from: 152, to: 152+12, style: (stroke: 2pt + luma(20%))),
        (from: 152+12, to: 228, style: (stroke: 2pt + luma(70%))),
      )
    })

    milestone(at: 0, "")
    milestone(at: 12, "")

    milestone(at: 76, "")
    milestone(at: 94, "")
  }
)

よって、228 cycles が答え。

== さらにロードストアパイプを6本に増やしたときの 1イタレーション時間

課題文の定義より「1本のロードストアパイプは 1cycle あたり 1スカラ値」を扱える。
6 本に増やした場合、ロードストアの転送部は6並列になる。

$ceil(64/6) = 11$ であるから p.6 の表を参考に、タイミングを表にすると @t3 のようになる。

#figure(
  table(
    columns: 4,
    align: (left, left, left, left),
    table.hline(),
    table.header([命令], [], [開始時間], [完了時間]),
    table.hline(),
    [LV]   , [V1, Rx]    , [$1$]         , [$12+11=23$],
    [MULTV], [a, V1]     , [$12+1=13$]   , [$12+7+32=51$],
    [LV]   , [V2, Ry]    , [$23+1=24$]   , [$23+12+11=46$],
    [ADDV] , [V3, V1, V2], [$24+12=36$]  , [$35+6+32=73$],
    [SV]   , [Ry, V3]    , [$73+4+1=78$] , [$77+12+11=100$],
    table.hline(),
  ),
  caption: [DAXPY on DLXV のタイミング],
) <t3>

#timeliney.timeline(
  show-grid: false,
  tasks-vline: false,
  milestone-line-style: (stroke: (paint: gray, dash: "dashed")),
  {
    import timeliney: *
      
    headerline(([時間], 100))
  
    taskgroup({
      task(
        "LV", 
        (from: 0, to: 12, style: (stroke: 2pt + luma(20%))),
        (from: 12, to: 23, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "MULTV",
        (from: 12, to: 12+7, style: (stroke: 2pt + luma(20%))),
        (from: 12+7, to: 51, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "LV",
        (from: 23, to: 23+12, style: (stroke: 2pt + luma(20%))),
        (from: 23+12, to: 46, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "ADDV",
        (from: 35, to: 35+6, style: (stroke: 2pt + luma(20%))),
        (from: 35+6, to: 73, style: (stroke: 2pt + luma(70%))),
      )
      task(
        "SV",
        (from: 77, to: 77+12, style: (stroke: 2pt + luma(20%))),
        (from: 77+12, to: 100, style: (stroke: 2pt + luma(70%))),
      )
    })

    milestone(at: 0, "")
    milestone(at: 12, "")

    milestone(at: 23, "")
    milestone(at: 41, "")

    milestone(at: 73, "")
    milestone(at: 89, "")
  }
)

よって、100 cycles が答え。

== ロード・ストアのレイテンシが大幅に増大し、76 になった場合

=== $R_infinity$ の値

=== ロード・ストアパイプを3本に増やした場合の $R_infinity$ の値

=== さらにロード・ストアパイプを増やすことによって、性能を向上できるか
