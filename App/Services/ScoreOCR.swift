import UIKit
import Vision

/// 写真から麻雀の点数らしき数値を抽出する（端末内・オフラインの Vision OCR）。
/// 精度はレイアウト依存のため「下書き入力」として使い、ユーザーが確認・修正する前提。
enum ScoreOCR {

    /// 画像から点数候補（最大4つ）を抽出する。結果はメインスレッドで返す。
    static func extractScores(from image: UIImage, completion: @escaping ([Int]) -> Void) {
        guard let cg = image.cgImage else { completion([]); return }

        let request = VNRecognizeTextRequest { req, _ in
            let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let scores = parse(lines: lines)
            DispatchQueue.main.async { completion(scores) }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["ja", "en"]

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            try? handler.perform([request])
        }
    }

    /// OCR行から点数候補を解析する。
    static func parse(lines: [String]) -> [Int] {
        var nums: [Int] = []
        let separators = CharacterSet(charactersIn: " 　:：/|()（）[]【】＋+")
        for line in lines {
            for token in line.components(separatedBy: separators) {
                let clean = token
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "，", with: "")
                if let v = Int(clean) { nums.append(v) }
            }
        }
        // 点数らしい候補：100点単位・|値|<=120000・0以外
        var cands = Array(Set(nums.filter { $0 != 0 && abs($0) <= 120_000 && $0 % 100 == 0 }))
        // 25000 に近い順に整理し、候補は最大12件
        cands.sort { abs($0 - 25_000) < abs($1 - 25_000) }
        cands = Array(cands.prefix(12))

        // 合計が100,000に最も近い4つの組合せを選ぶ（ノイズ除去に有効）
        if let best = bestFour(cands) { return best }
        return Array(cands.prefix(4)).sorted(by: >)
    }

    private static func bestFour(_ c: [Int]) -> [Int]? {
        guard c.count >= 4 else { return nil }
        var best: [Int]? = nil
        var bestDiff = Int.max
        let n = c.count
        for i in 0..<n {
            for j in (i + 1)..<n {
                for k in (j + 1)..<n {
                    for l in (k + 1)..<n {
                        let diff = abs(c[i] + c[j] + c[k] + c[l] - 100_000)
                        if diff < bestDiff { bestDiff = diff; best = [c[i], c[j], c[k], c[l]] }
                    }
                }
            }
        }
        return best?.sorted(by: >)
    }
}
