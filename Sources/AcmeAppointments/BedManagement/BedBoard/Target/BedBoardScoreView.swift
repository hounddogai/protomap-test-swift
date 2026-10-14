import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board score.
    final class BedBoardScoreView {
        var code: String
        var title: String
        var refillsText: String
        var patientRef: String
        var score: String
        var capacity: String
        var currency: String
        var name: String
        var statusLabel: String

        init(code: String, title: String, refillsText: String, patientRef: String, score: String, capacity: String, currency: String, name: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refillsText = refillsText
            self.patientRef = patientRef
            self.score = score
            self.capacity = capacity
            self.currency = currency
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardScoreView(_ item: BedBoardScore) -> BedBoardScoreView {
        return BedBoardScoreView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            refillsText: String(item.refills),
            patientRef: item.patientRef,
            score: String(format: "%.2f", item.score),
            capacity: String(item.capacity),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardScoreViews(_ items: [BedBoardScore]) -> [BedBoardScoreView] {
        var views: [BedBoardScoreView] = []
        for item in items {
            views.append(toBedBoardScoreView(item))
        }
        return views
    }

    static func sumBedBoardScoreView(_ view: BedBoardScoreView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedRefills) + parsedScore + Double(parsedCapacity)
    }
}
