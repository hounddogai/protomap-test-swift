import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched network agreement.
    final class BatchedNetworkAgreementView {
        var code: String
        var labelText: String
        var currency: String
        var scoreText: String
        var startsAtText: String
        var version: String
        var durationMinutes: String
        var title: String
        var ceiling: String
        var locale: String
        var phoneText: String
        var statusLabel: String

        init(code: String, labelText: String, currency: String, scoreText: String, startsAtText: String, version: String, durationMinutes: String, title: String, ceiling: String, locale: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.currency = currency
            self.scoreText = scoreText
            self.startsAtText = startsAtText
            self.version = version
            self.durationMinutes = durationMinutes
            self.title = title
            self.ceiling = ceiling
            self.locale = locale
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedNetworkAgreementView(_ item: BatchedNetworkAgreement) -> BatchedNetworkAgreementView {
        return BatchedNetworkAgreementView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            currency: item.currency,
            scoreText: String(format: "%.2f", item.score),
            startsAtText: String(item.startsAt),
            version: String(item.version),
            durationMinutes: String(item.durationMinutes),
            title: Kit.Text.truncate(item.title, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedNetworkAgreementViews(_ items: [BatchedNetworkAgreement]) -> [BatchedNetworkAgreementView] {
        var views: [BatchedNetworkAgreementView] = []
        for item in items {
            views.append(toBatchedNetworkAgreementView(item))
        }
        return views
    }

    static func sumBatchedNetworkAgreementView(_ view: BatchedNetworkAgreementView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedScore + Double(parsedStartsAt) + Double(parsedVersion)
    }
}
