import Foundation

/// 風（席）。東南西北。
enum Wind: String, Codable, CaseIterable {
    case east = "東"
    case south = "南"
    case west = "西"
    case north = "北"

    /// 「東家」のような表示名
    var seatName: String { "\(rawValue)家" }
}

/// 1人のプレイヤー（席・点数・自分かどうか）
struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let wind: Wind
    let score: Int
    let isUser: Bool

    init(id: UUID = UUID(), name: String, wind: Wind, score: Int, isUser: Bool) {
        self.id = id
        self.name = name
        self.wind = wind
        self.score = score
        self.isUser = isUser
    }
}
