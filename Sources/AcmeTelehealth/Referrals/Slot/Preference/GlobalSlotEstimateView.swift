import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global slot estimate.
    final class GlobalSlotEstimateView {
        var code: String
        var title: String
        var acuity: String
        var margin: String
        var expiresAt: String
        var channel: String
        var allergy: String
        var currency: String
        var statusLabel: String

        init(code: String, title: String, acuity: String, margin: String, expiresAt: String, channel: String, allergy: String, currency: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.margin = margin
            self.expiresAt = expiresAt
            self.channel = channel
            self.allergy = allergy
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSlotEstimateView(_ item: GlobalSlotEstimate) -> GlobalSlotEstimateView {
        return GlobalSlotEstimateView(
            code: item.code,
            title: item.title,
            acuity: String(item.acuity),
            margin: String(format: "%.2f", item.margin),
            expiresAt: String(item.expiresAt),
            channel: item.channel,
            allergy: item.allergy,
            currency: Kit.Text.truncate(item.currency, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSlotEstimateViews(_ items: [GlobalSlotEstimate]) -> [GlobalSlotEstimateView] {
        var views: [GlobalSlotEstimateView] = []
        for item in items {
            views.append(toGlobalSlotEstimateView(item))
        }
        return views
    }

    static func sumGlobalSlotEstimateView(_ view: GlobalSlotEstimateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedAcuity) + parsedMargin + Double(parsedExpiresAt)
    }
}
