import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network score.
    final class NetworkScoreView {
        var code: String
        var title: String
        var sequenceText: String
        var limitText: String
        var cost: String
        var notes: String
        var encounterID: String
        var acuity: String
        var allergy: String
        var facility: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, sequenceText: String, limitText: String, cost: String, notes: String, encounterID: String, acuity: String, allergy: String, facility: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequenceText = sequenceText
            self.limitText = limitText
            self.cost = cost
            self.notes = notes
            self.encounterID = encounterID
            self.acuity = acuity
            self.allergy = allergy
            self.facility = facility
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkScoreView(_ item: NetworkScore) -> NetworkScoreView {
        return NetworkScoreView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            sequenceText: String(item.sequence),
            limitText: String(item.limit),
            cost: String(format: "%.2f", item.cost),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            acuity: String(item.acuity),
            allergy: item.allergy,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkScoreViews(_ items: [NetworkScore]) -> [NetworkScoreView] {
        var views: [NetworkScoreView] = []
        for item in items {
            views.append(toNetworkScoreView(item))
        }
        return views
    }

    static func sumNetworkScoreView(_ view: NetworkScoreView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedSequence) + Double(parsedLimit) + parsedCost
    }
}
