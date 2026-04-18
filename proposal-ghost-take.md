# 企画書：GHOST TAKE

## タイトル
**「録ろうとする意思」を消滅させる、信号経路常駐型バッファレコーダー**

---

## 顧客ニーズ
宅録・作曲志向のギタリストが、即興で生まれた良いフレーズを録音する前に失っている。スマホを取り出す・アプリを開く・録音ボタンを押す——この数秒の操作が、創造の閾値を超えてしまう。

---

## インサイト
「録ろうとする意思が、アイデアを殺す」

録音アプリを持っているのに使わない。DAWを立ち上げっぱなしにしても、ボタンを押す瞬間に創造の流れが途切れる。ギタリストが本当に求めているのは「良い録音環境」ではなく、**「弾いていたら、もうそこに残っている」という状態**だ。

記録への意志が介在しないこと——その受動的な安心感こそが、創造性を解放する。

---

## コンセプト
> 「弾いていれば、それでいい。残るべきものは、残っている。」

GHOST TAKEはギターとオーディオインターフェースの間の信号経路に常駐する小型デバイス。電源ボタンも録音ボタンも存在しない。ギターを弾き始めると自動で起動し、常に直近5分間をバッファリングし続ける。「今のいい」と思った瞬間にフットスイッチを踏むと、直前60秒が自動保存される。弾くことだけに集中していれば、思考は介在しない。

---

## プロダクト名
**GHOST TAKE（ゴーストテイク）**

---

## シグネチャーディテール
### 「心拍LED」——存在を忘れさせるための、存在の証明

GHOST TAKEには電源ボタンがない。唯一の視覚的要素は、ボディ正面の**直径3mmの単色LED**のみ。

このLEDは、人間の安静時心拍数と同じリズム（毎分60回）で静かに点滅し続ける。バッファリング中であることを示しながら、ユーザーに「このデバイスは今、生きている」という確信を与える。フットスイッチで保存した瞬間だけ、LEDが3回速く点滅してリズムに戻る——保存されたことを「身体で」知らせる、音も画面も不要なフィードバック。

ギターを弾き終えて5分後、信号を検知しなくなるとLEDが消え、デバイスは眠る。

> この心拍は「録音中」ではなく「待機中」を示している。見張っているのではない、ただ一緒にいる——その差が、ユーザーの演奏態度を変える。

---

## デザインの必然性
### なぜ「信号経路に介在する形」でなければならないか

スマホアプリやDAWは「起動するもの」だ。存在しない状態からユーザーが呼び出す。その呼び出しの瞬間に創造の流れは止まる。

GHOST TAKEはケーブルの延長として存在する。**ギターとインターフェースをつなぐ行為そのものが、録音環境の構築と同義**になる。ケーブルを接続した瞬間から、あらゆる演奏が保護される。この「介在」という形態は、アプリには物理的に不可能だ——アプリは信号経路の外側にいる。

サイズは名刺2枚分（幅60mm×奥行40mm×厚さ18mm）。デスクの上に「置く」のではなく、ケーブルの途中に「吊るされる」イメージ。存在を主張しない形。ケーブルマネジメントの一部として視界に溶け込む。

フットスイッチは**演奏を止めずに操作できる唯一のUI**だ。画面もタッチパネルも不要——足の記憶が、発想の記録になる。

---

## プロダクトイメージ（画像プロンプト）
```
Extreme close-up product photograph of GHOST TAKE — a matte black aluminum
device the size of two stacked credit cards, with a single 3mm amber LED
glowing in its center. Two guitar cables (6.35mm TS) enter and exit from
opposite ends of the device, their black braided sleeves disappearing into
the shallow depth of field.

LENS & DISTANCE: 100mm macro lens, 25cm from the subject, f/3.5.
The LED is in critical focus — sharp enough to see the dome shape of the
lens. The cable jacks at both ends fall into progressive blur.

LIGHTING: Complete darkness except one narrow raking light from the left
at 15-degree angle, 40cm away, bare LED strip (3000K). It catches only
the brushed aluminum edge and the dome of the status LED. The top surface
of the device is in near-shadow, texture barely readable. No reflections.
No bounce fill. Shadow is the majority of the frame.

COLOR GRADE: Pushed Kodak Tri-X 400 simulation — near monochromatic,
the only color information retained in the amber LED (warm gold) against
total black-and-gray. Grain visible at 100%.

COMPOSITION: The LED occupies the exact center of the frame — a single
point of warm light surrounded by darkness. The device's body extends left
and right, anchoring the light in physical context. The cables enter from
lower-left and exit upper-right, creating a diagonal that implies signal
flow through the frame. The first and only eye-landing point is the amber
LED — everything else in the image exists to justify that single point.

MOOD: The feeling of a pilot light in a dark room.
      Something is on. Something is listening. Something will remember.
```

---

## プロダクトの使用方法

1. **接続**：ギターとオーディオインターフェースの間のシールドケーブル経路にGHOST TAKEを挟む（IN端子・OUT端子、どちらの向きでも同一）
2. **自動起動**：ギターを弾くと信号を検知し、LEDが心拍リズムで点滅開始。バッファリング開始
3. **演奏**：通常通り弾くだけ。何も意識しない
4. **保存**：「今のよかった」と思った瞬間にフットスイッチを踏む。LEDが3回速く点滅し、直前60秒がマイクロSDカードに保存される
5. **確認**：演奏後、マイクロSDをPCに挿入するか、専用アプリ（Bluetooth経由）でファイルにアクセス。タイムスタンプ付きで一覧表示

---

## 活用シーン・使用中のイメージ（画像プロンプト）
```
A guitarist's right foot in worn canvas sneakers, hovering 3cm above
a footswitch mounted on the floor beside a pedalboard. The foot has
not yet pressed it. This is the moment of decision.

GHOST TAKE is visible in the mid-ground, hanging in the cable between
a guitar and an interface on a nearby desk — it is out of focus but
the amber LED heartbeat is unmistakably warm against the dark background.

LENS & DISTANCE: 35mm, f/1.8, camera at floor level (15cm from ground),
angled up 20 degrees toward the footswitch. Distance to foot: 50cm.
The foot is in sharp focus. GHOST TAKE in the background is soft but
readable — its LED the only lit element in the background darkness.

LIGHTING: A single practical lamp on the desk behind the scene provides
warm backlight (2700K), creating a halo around the foot and illuminating
the underside of the desk. No other light source. The floor is in
near-darkness, just enough texture in the hardwood boards to read depth.

COLOR GRADE: Fujifilm Neopan Acros 100 II push — high contrast, cool
shadows, the only warmth in frame from the desk lamp bloom and the LED.
Gentle grain. The foot reads as slightly warm against cool floor.

COMPOSITION: The foot's heel is at the lower-left, toes pointing toward
the footswitch at center-right. The footswitch itself is at the rule-of-
thirds intersection. GHOST TAKE's LED is at the upper-right third — a
triangle of three elements (heel, switch, LED) that the eye travels.
The first eye-landing point is the gap between foot and switch — 3cm
of intention suspended in air.

MOOD: The millisecond before something is kept forever.
```

---

## 3C分析

### Customer（顧客）
- **メイン**：宅録・作曲志向のギタリスト（20〜40代）、即興を大切にする層
- **サブ**：ジャムセッション派、アイデアのスケッチを習慣化したい層
- **行動特性**：「あのフレーズ忘れた」経験が複数回ある。DAWは持っているが起動が面倒
- **価値観**：創造の瞬間を大切にしたい。技術よりも「その瞬間の何か」を残したい

### Competitor（競合）
| 競合 | 弱点 |
|------|------|
| スマホ録音アプリ | 信号経路の外側。起動操作が必要。ギター信号を直接取れない |
| ZOOMポータブルレコーダー | 別途マイクを立てるか接続が必要。常時電源が前提でない |
| DAW立ち上げっぱなし | PC必須。バッファリングは手動設定。「ファイルがたまる問題」が残る |
| 汎用バッファリングアプリ | 信号経路外。ギター専用最適化なし。操作UIが残る |

### Company（自社）
- 楽器アクセサリーブランド or 宅録ガジェット系スタートアップ
- 強み：ギタリストの信号経路への深い理解、フットスイッチUXの設計力
- 製造：マイクロSD録音回路＋信号バッファ基板。小型化コストは下がっている
- 初期販路：Makuake（「忘れたフレーズ」のストーリーで共感拡散） → EC → 楽器店

---

## USP（Unique Selling Proposition）
> **「世界で唯一、ギターとインターフェースの間に住む録音デバイス。電源ボタンも録音ボタンも存在しない。弾いていれば、残るべきものは残っている。」**

スマホアプリとの決定的な違いは「信号経路への物理的介在」。アプリは信号の外側にいる。GHOST TAKEは信号そのものの中にいる。この差がゼロフリクションを実現する。

---

## 価格帯
- スタンダード（マイクロSD 32GB付属）：**¥14,800**
- プロ（マイクロSD 128GB＋Bluetooth対応）：**¥19,800**
