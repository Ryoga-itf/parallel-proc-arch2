#import "../template.typ": *
#import "./bxbibwrite.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv

#let env = parse_dotenv(read("../.env"))

#show: project.with(
  week: "第3回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 11 月 26 日",
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

== 課題3-3：近年の x86系プロセッサにおけるAVX512 の対応状況の調査

各プロセッサにおける AVX-512 の対応は @t1 のようになった。

#show table: set text(size: 0.55em)
#figure(
  table(
    columns: 7,
    align: (auto, auto, auto, auto, auto, auto, auto),
    table.hline(),
    table.header([メーカー], [プロセッサ], [アーキテクチャ], [対応状況], [物理データパス幅], [実行方式], [備考]),
    table.hline(),
    [AMD]  , [Ryzen 9000 (Granite Ridge)]     , [Zen 5]         , [対応 (Full)]   , [512-bit]    , [ネイティブ]  , [クロック低下は軽微],
    [AMD]  , [EPYC 9005 (Turin)]              , [Zen 5]         , [対応 (Full)]   , [512-bit]    , [ネイティブ]  , [],
    [AMD]  , [Ryzen AI 300 (Strix Point)]     , [Zen 5 (Mobile)], [対応 (Full)]   , [256-bit]    , [ダブルポンプ], [2サイクルで実行],
    [AMD]  , [EPYC Dense (Turin Dense)]       , [Zen 5c]        , [対応 (Full)]   , [256-bit (?)], [ダブルポンプ], [],
    [Intel], [Xeon 6 P-core (Granite Rapids)] , [Redwood Cove+] , [対応 (AVX10.1)], [512-bit]    , [ネイティブ]  , [],
    [Intel], [Xeon 6 E-core (Sierra Forest)]  , [Sierra Glen]   , [非対応]        , [N/A]    , [N/A]  , [AVX2/AVX-VNNIまで],
    [Intel], [Core Ultra 2 (Arrow/Lunar Lake)], [Lion Cove / Skymont] , [非対応]  , [256-bit (P)]    , [N/A]  , [AVX-VNNI (VEX)のみ利用可能],
    [Intel], [Next Gen (Nova Lake)]           , [Panther Cove (?)]    , [対応予定 (AVX10.1)], [512/256-bit], [混合可能 (?)]  , [P/E両コアで命令セットが統一される],
    table.hline(),
  ),
  caption: [各プロセッサにおける対応状況、? の部分は推定],
) <t1>

現在、AVX-512を最も広範かつ高性能に利用できるのはAMD Zen 5（デスクトップ/サーバー）であることがわかった。
Intelはサーバー（P-core）では強力な実装を持つが、クライアント側ではAVX10による統合作業の途上にあり、現状ではサポートが一時的に空白となっている。

以下詳細について述べる。

2024年から2025年にかけたx86エコシステムにおける512ビットベクトル処理（AVX-512）の状況は、IntelとAMDで対照的なアプローチが採られている。

/ AMD:\
  最新のZen 5アーキテクチャにおいて、デスクトップおよびサーバー向けにネイティブ512ビットのデータパスを実装し、AVX-512を全面的に推進している。
  一方でモバイル向けには電力効率を重視し、命令セットはサポートしつつも内部的には256ビットで処理するダブルポンピング手法を使い分けている。@numberworld

/ Intel:\
  ハイブリッドアーキテクチャ（P-core/E-core混載）における命令セットの不一致を解消するため、AVX10 (Advanced Vector Extensions 10) への移行を進めている。
  サーバー向け（Granite Rapids）では完全な512ビットサポートを提供するが、現在のクライアント向け（Arrow Lake）ではAVX-512は無効化されており、本格的な統合は将来のNova Lake世代（AVX10.2）を待つ必要がある。@techpowerup

=== 近年の（Zen 5世代）AMD プロセッサの対応状況

AMDはZen 4で初めてAVX-512をサポートしたが、Zen 5では製品セグメント（用途）に応じて物理的な実装形態を明確に二分している。

/ デスクトップ (Ryzen 9000) および サーバー (EPYC Turin):\
  これらの高性能セグメントでは、真の512ビットデータパスが採用されている。

  物理実装においては、浮動小数点演算ユニット（FPU）およびロード/ストアユニットが物理的に512ビット幅に拡張された。これにより、AVX-512命令を1クロックサイクルで実行可能である 。@amd @phoronix
  また、性能への影響として、従来の「ダブルポンピング（2サイクルかけて処理）」と比較し、理論上のスループットは2倍となる。特にHPCやAI推論において顕著な性能向上が見られる。

/ モバイル (Ryzen AI 300 / Strix Point) および 高密度サーバー (Zen 5c):\
  モバイル向けおよびクラウドネイティブ向け（Zen 5c）では、エリア効率と電力効率が最優先されるため、異なるアプローチが採られている。

  物理実装においては、データパスは256ビット幅に留められている。
  また、実行方式としてはダブルポンピングで、512ビットの命令（ISA）はサポートしているが、内部的に「256ビット演算 x 2回」に分割して実行される。これにより、物理的なダイサイズを節約しつつ、ソフトウェアの互換性を維持している。@numberworld @hwcooling

  ユーザーからは「AVX-512対応」として見えるが、ピーク性能はデスクトップ版の半分（クロックあたり）となっているといえる。

=== 近年の Intel プロセッサの対応状況

Intelは「AVX-512」という名称から、機能（ISA）とベクトル長（VL）を分離して管理する「AVX10」へとブランドと仕様を再定義した。

/ サーバー向け (Xeon 6):\
  P-core製品 (Granite Rapids) においては AVX10.1をサポートし、物理的にも512ビット実行ユニットを搭載している。
  従来のAVX-512と互換性があり、AMX（行列演算拡張）と合わせて高いAI処理能力を持つ。@hackernews

  E-core製品 (Sierra Forest) においては、AVX-512およびAVX10は非対応である。
  AVX2およびAVX-VNNI（256ビット）までのサポートに留まる。@serverthehome

/ クライアント向け (Core Ultra Series 2):\
  Arrow Lake / Lunar Lake といったの製品では、P-coreとE-coreの命令セットを揃えるため、AVX-512機能は無効化（または非搭載）されている。

  2026年以降予定のNova Lakeにおいて、P-core/E-core両方でAVX10.2がサポートされ、コンシューマー機でも（256ビット幅での実行となる可能性が高いが）AVX-512命令セットが解禁される見込みである。@techpowerup

技術的な課題として、過去のIntel CPU（Skylake-X等）では、AVX-512実行時に発熱を抑えるため大幅なクロックダウン（AVX Offset）が発生し、システム全体の性能を低下させることがあったそうだ。
また、VP2INTERSECT というデータセットの共通集合を求める命令は、IntelはTiger Lakeで導入したが、どうも「他の命令でエミュレーションした方が速い」という論文が出たりした。@arxiv そのせいか、その後削除（非推奨化）した。
しかし、AMDはZen 5でこの命令のサポートを追加しており、特定のデータベース処理などではAMDが機能的に優位にあるというねじれ現象が起きている。@numberworld @techpowerup2

#bibliography-list(
  title: "参考文献", // 節見出しの文言
)[
  #align(left, [
    #bib-item(<numberworld>)[
      #align(left, [
        Zen5's AVX512 Teardown + More..., https://www.numberworld.org/blogs/2024_8_7_zen5_avx512_teardown/,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<techpowerup>)[
      #align(left, [
        Intel Officially Confirms AVX10.2 and APX Support in "Nova Lake", https://www.techpowerup.com/342881/intel-officially-confirms-avx10-2-and-apx-support-in-nova-lake,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<amd>)[
      #align(left, [
        Leadership HPC Performance with 5th Generation AMD EPYC Processors, https://www.amd.com/en/blogs/2025/leadership-hpc-performance-with-5th-generation-amd.html,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<phoronix>)[
      #align(left, [
        AMD Zen 5 Overview With Ryzen 9000 Series & Ryzen AI 300, https://www.phoronix.com/review/amd-zen5-ryzen-9000,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<hwcooling>)[
      #align(left, [
        Zen 5 tested: Mobile core differs considerably from desktop one, https://www.hwcooling.net/en/zen-5-tested-mobile-core-differs-considerably-from-desktop-one/,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<hackernews>)[
      #align(left, [
        While it does seem that AVX10 was mainly designed for consumer CPUs so they could use modern vector instructions without 512-bit vectors, the upcoming Arrow Lake will not have it., https://news.ycombinator.com/item?id=41184123,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<serverthehome>)[
      #align(left, [
        Intel Xeon Clearwater Forest with 288 Cores on Intel 18A at Hot Chips 2025, https://www.servethehome.com/intel-xeon-clearwater-forest-with-288-cores-on-intel-18a-at-hot-chips-2025/,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<arxiv>)[
      #align(left, [
        [2112.06342] Faster-Than-Native Alternatives for x86 VP2INTERSECT Instructions, https://arxiv.org/abs/2112.06342,
        2025 年 11 月 25 日閲覧
      ])
    ]
    #bib-item(<techpowerup2>)[
      #align(left, [
        AMD Zen 5 Details Emerge with GCC "Znver5" Patch: New AVX Instructions, Larger Pipelines, https://www.techpowerup.com/318991/amd-zen-5-details-emerge-with-gcc-znver5-patch-new-avx-instructions-larger-pipelines,
        2025 年 11 月 25 日閲覧
      ])
    ]
  ])
]
