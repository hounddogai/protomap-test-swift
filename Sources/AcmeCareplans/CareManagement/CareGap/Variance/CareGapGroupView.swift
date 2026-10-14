import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap group.
    final class CareGapGroupView {
        var code: String
        var label: String
        var payerText: String
        var score: String
        var title: String
        var pinned: String
        var retries: String
        var amountText: String
        var approved: String
        var rate: String
        var statusLabel: String

        init(code: String, label: String, payerText: String, score: String, title: String, pinned: String, retries: String, amountText: String, approved: String, rate: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payerText = payerText
            self.score = score
            self.title = title
            self.pinned = pinned
            self.retries = retries
            self.amountText = amountText
            self.approved = approved
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapGroupView(_ item: CareGapGroup) -> CareGapGroupView {
        return CareGapGroupView(
            code: item.code,
            label: item.label,
            payerText: item.payer,
            score: String(format: "%.2f", item.score),
            title: Kit.Text.truncate(item.title, limit: 120),
            pinned: "\(item.pinned)",
            retries: String(item.retries),
            amountText: String(format: "%.2f", item.amount),
            approved: "\(item.approved)",
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapGroupViews(_ items: [CareGapGroup]) -> [CareGapGroupView] {
        var views: [CareGapGroupView] = []
        for item in items {
            views.append(toCareGapGroupView(item))
        }
        return views
    }

    static func sumCareGapGroupView(_ view: CareGapGroupView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedScore + Double(parsedRetries) + parsedAmount
    }
}
