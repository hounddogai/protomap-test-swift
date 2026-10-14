import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol estimate.
    final class CareProtocolEstimateView {
        var code: String
        var label: String
        var channel: String
        var contactEmail: String
        var cost: String
        var procedureCode: String
        var timezone: String
        var ceilingText: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, label: String, channel: String, contactEmail: String, cost: String, procedureCode: String, timezone: String, ceilingText: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.contactEmail = contactEmail
            self.cost = cost
            self.procedureCode = procedureCode
            self.timezone = timezone
            self.ceilingText = ceilingText
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolEstimateView(_ item: CareProtocolEstimate) -> CareProtocolEstimateView {
        return CareProtocolEstimateView(
            code: item.code,
            label: item.label,
            channel: item.channel,
            contactEmail: item.contactEmail,
            cost: String(format: "%.2f", item.cost),
            procedureCode: item.procedureCode,
            timezone: item.timezone,
            ceilingText: String(format: "%.2f", item.ceiling),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolEstimateViews(_ items: [CareProtocolEstimate]) -> [CareProtocolEstimateView] {
        var views: [CareProtocolEstimateView] = []
        for item in items {
            views.append(toCareProtocolEstimateView(item))
        }
        return views
    }

    static func sumCareProtocolEstimateView(_ view: CareProtocolEstimateView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCost + parsedCeiling + Double(parsedEndsAt)
    }
}
