#import "../template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv

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

#show table: set text(size: 0.55em)
#figure(
  table(
    columns: 3,
    align: (left, left, auto, auto),
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

== lane を導入し、各々のベクトル演算が1/2 の時間で終わると仮定したときの 1 イタレーションの実行時間
