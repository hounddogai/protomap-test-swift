import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach adjustment.
    final class OutreachAdjustmentView {
        var codeText: String
        var title: String
        var region: String
        var summaryText: String
        var endsAtText: String
        var amount: String
        var refills: String
        var createdAt: String
        var currency: String
        var statusLabel: String

        init(codeText: String, title: String, region: String, summaryText: String, endsAtText: String, amount: String, refills: String, createdAt: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.region = region
            self.summaryText = summaryText
            self.endsAtText = endsAtText
            self.amount = amount
            self.refills = refills
            self.createdAt = createdAt
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachAdjustmentView(_ item: OutreachAdjustment) -> OutreachAdjustmentView {
        return OutreachAdjustmentView(
            codeText: item.code,
            title: item.title,
            region: item.region,
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            endsAtText: String(item.endsAt),
            amount: String(format: "%.2f", item.amount),
            refills: String(item.refills),
            createdAt: String(item.createdAt),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachAdjustmentViews(_ items: [OutreachAdjustment]) -> [OutreachAdjustmentView] {
        var views: [OutreachAdjustmentView] = []
        for item in items {
            views.append(toOutreachAdjustmentView(item))
        }
        return views
    }

    static func sumOutreachAdjustmentView(_ view: OutreachAdjustmentView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedEndsAt) + parsedAmount + Double(parsedRefills)
    }
}
