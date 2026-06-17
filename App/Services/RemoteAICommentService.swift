import Foundation

/// バックエンド（Cloudflare Worker）経由でAI解説を取得する。
/// APIキーはアプリに埋め込まず、Worker側のSecretで管理する。
/// 失敗時は呼び出し側で LocalCommentService にフォールバックする想定。
struct RemoteAICommentService {
    /// 解説エンドポイント（beqd1106 の Worker）
    let endpoint = URL(string: "https://beqd1106.com/api/oorasu/comment")!

    enum AIError: Error { case server, empty, network }

    struct Result {
        let text: String
        let source: String   // "gemini" / "workers-ai"
    }

    /// 条件のファクト文字列を渡してAI解説を取得（数値はアプリ側で確定済み）。
    func comment(facts: String) async throws -> Result {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["facts": facts])
        req.timeoutInterval = 20

        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw AIError.network
        }
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.server
        }
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let text = (obj?["comment"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw AIError.empty
        }
        let source = (obj?["source"] as? String) ?? "ai"
        return Result(text: text, source: source)
    }
}
