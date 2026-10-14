import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default risk score threshold.
    final class DefaultRiskScoreThresholdView {
        var code: String
        var titleText: String
        var graceDays: String
        var discount: String
        var approved: String
        var updatedAt: String
        var ceilingText: String
        var checksum: String
        var currency: String
        var procedureCode: String
        var sequence: String
        var statusLabel: String

        init(code: String, titleText: String, graceDays: String, discount: String, approved: String, updatedAt: String, ceilingText: String, checksum: String, currency: String, procedureCode: String, sequence: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.graceDays = graceDays
            self.discount = discount
            self.approved = approved
            self.updatedAt = updatedAt
            self.ceilingText = ceilingText
            self.checksum = checksum
            self.currency = currency
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRiskScoreThresholdView(_ item: DefaultRiskScoreThreshold) -> DefaultRiskScoreThresholdView {
        return DefaultRiskScoreThresholdView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            graceDays: String(item.graceDays),
            discount: String(format: "%.2f", item.discount),
            approved: "\(item.approved)",
            updatedAt: String(item.updatedAt),
            ceilingText: String(format: "%.2f", item.ceiling),
            checksum: item.checksum,
            currency: item.currency,
            procedureCode: item.procedureCode,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRiskScoreThresholdViews(_ items: [DefaultRiskScoreThreshold]) -> [DefaultRiskScoreThresholdView] {
        var views: [DefaultRiskScoreThresholdView] = []
        for item in items {
            views.append(toDefaultRiskScoreThresholdView(item))
        }
        return views
    }

    static func sumDefaultRiskScoreThresholdView(_ view: DefaultRiskScoreThresholdView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedGraceDays) + parsedDiscount + Double(parsedUpdatedAt)
    }
}
