import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive network request.
    final class AdaptiveNetworkRequestView {
        var code: String
        var name: String
        var batchSize: String
        var contactEmailText: String
        var scoreText: String
        var refillsText: String
        var createdAt: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, batchSize: String, contactEmailText: String, scoreText: String, refillsText: String, createdAt: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.contactEmailText = contactEmailText
            self.scoreText = scoreText
            self.refillsText = refillsText
            self.createdAt = createdAt
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveNetworkRequestView(_ item: AdaptiveNetworkRequest) -> AdaptiveNetworkRequestView {
        return AdaptiveNetworkRequestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 40),
            batchSize: String(item.batchSize),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 64),
            scoreText: String(format: "%.2f", item.score),
            refillsText: String(item.refills),
            createdAt: String(item.createdAt),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveNetworkRequestViews(_ items: [AdaptiveNetworkRequest]) -> [AdaptiveNetworkRequestView] {
        var views: [AdaptiveNetworkRequestView] = []
        for item in items {
            views.append(toAdaptiveNetworkRequestView(item))
        }
        return views
    }

    static func sumAdaptiveNetworkRequestView(_ view: AdaptiveNetworkRequestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedBatchSize) + parsedScore + Double(parsedRefills)
    }
}
