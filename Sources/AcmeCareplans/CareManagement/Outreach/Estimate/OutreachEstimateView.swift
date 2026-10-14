import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach estimate.
    final class OutreachEstimateView {
        var codeText: String
        var name: String
        var segment: String
        var timezone: String
        var unitText: String
        var amount: String
        var statusLabel: String

        init(codeText: String, name: String, segment: String, timezone: String, unitText: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.segment = segment
            self.timezone = timezone
            self.unitText = unitText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachEstimateView(_ item: OutreachEstimate) -> OutreachEstimateView {
        return OutreachEstimateView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            segment: item.segment,
            timezone: item.timezone,
            unitText: item.unit,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachEstimateViews(_ items: [OutreachEstimate]) -> [OutreachEstimateView] {
        var views: [OutreachEstimateView] = []
        for item in items {
            views.append(toOutreachEstimateView(item))
        }
        return views
    }

    static func sumOutreachEstimateView(_ view: OutreachEstimateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
