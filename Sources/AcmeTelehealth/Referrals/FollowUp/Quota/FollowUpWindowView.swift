import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up window.
    final class FollowUpWindowView {
        var code: String
        var titleText: String
        var payerText: String
        var dosageMg: String
        var discount: String
        var priority: String
        var retries: String
        var sequence: String
        var statusLabel: String

        init(code: String, titleText: String, payerText: String, dosageMg: String, discount: String, priority: String, retries: String, sequence: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.payerText = payerText
            self.dosageMg = dosageMg
            self.discount = discount
            self.priority = priority
            self.retries = retries
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpWindowView(_ item: FollowUpWindow) -> FollowUpWindowView {
        return FollowUpWindowView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            payerText: item.payer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            discount: String(format: "%.2f", item.discount),
            priority: String(item.priority),
            retries: String(item.retries),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpWindowViews(_ items: [FollowUpWindow]) -> [FollowUpWindowView] {
        var views: [FollowUpWindowView] = []
        for item in items {
            views.append(toFollowUpWindowView(item))
        }
        return views
    }

    static func sumFollowUpWindowView(_ view: FollowUpWindowView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDosageMg + parsedDiscount + Double(parsedPriority)
    }
}
