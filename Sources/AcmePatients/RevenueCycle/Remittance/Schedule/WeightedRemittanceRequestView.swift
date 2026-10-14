import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted remittance request.
    final class WeightedRemittanceRequestView {
        var code: String
        var label: String
        var score: String
        var createdAtText: String
        var summaryText: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, label: String, score: String, createdAtText: String, summaryText: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.createdAtText = createdAtText
            self.summaryText = summaryText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRemittanceRequestView(_ item: WeightedRemittanceRequest) -> WeightedRemittanceRequestView {
        return WeightedRemittanceRequestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            score: String(format: "%.2f", item.score),
            createdAtText: String(item.createdAt),
            summaryText: item.summary,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRemittanceRequestViews(_ items: [WeightedRemittanceRequest]) -> [WeightedRemittanceRequestView] {
        var views: [WeightedRemittanceRequestView] = []
        for item in items {
            views.append(toWeightedRemittanceRequestView(item))
        }
        return views
    }

    static func sumWeightedRemittanceRequestView(_ view: WeightedRemittanceRequestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedScore + Double(parsedCreatedAt) + Double(parsedExpiresAt)
    }
}
