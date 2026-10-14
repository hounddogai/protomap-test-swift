import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal eligibility record.
    final class SeasonalEligibilityRecordView {
        var code: String
        var title: String
        var phone: String
        var cost: String
        var patientRef: String
        var expiresAt: String
        var batchSize: String
        var payerText: String
        var graceDaysText: String
        var currencyText: String
        var statusLabel: String

        init(code: String, title: String, phone: String, cost: String, patientRef: String, expiresAt: String, batchSize: String, payerText: String, graceDaysText: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.cost = cost
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.payerText = payerText
            self.graceDaysText = graceDaysText
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalEligibilityRecordView(_ item: SeasonalEligibilityRecord) -> SeasonalEligibilityRecordView {
        return SeasonalEligibilityRecordView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            phone: Kit.Text.truncate(item.phone, limit: 120),
            cost: String(format: "%.2f", item.cost),
            patientRef: item.patientRef,
            expiresAt: String(item.expiresAt),
            batchSize: String(item.batchSize),
            payerText: item.payer,
            graceDaysText: String(item.graceDays),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalEligibilityRecordViews(_ items: [SeasonalEligibilityRecord]) -> [SeasonalEligibilityRecordView] {
        var views: [SeasonalEligibilityRecordView] = []
        for item in items {
            views.append(toSeasonalEligibilityRecordView(item))
        }
        return views
    }

    static func sumSeasonalEligibilityRecordView(_ view: SeasonalEligibilityRecordView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCost + Double(parsedExpiresAt) + Double(parsedBatchSize)
    }
}
