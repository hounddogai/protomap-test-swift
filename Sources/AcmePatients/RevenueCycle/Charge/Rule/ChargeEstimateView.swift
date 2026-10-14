import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge estimate.
    final class ChargeEstimateView {
        var code: String
        var nameText: String
        var rate: String
        var expiresAt: String
        var priority: String
        var patientRef: String
        var quantity: String
        var startsAt: String
        var copay: String
        var limit: String
        var statusLabel: String

        init(code: String, nameText: String, rate: String, expiresAt: String, priority: String, patientRef: String, quantity: String, startsAt: String, copay: String, limit: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.rate = rate
            self.expiresAt = expiresAt
            self.priority = priority
            self.patientRef = patientRef
            self.quantity = quantity
            self.startsAt = startsAt
            self.copay = copay
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toChargeEstimateView(_ item: ChargeEstimate) -> ChargeEstimateView {
        return ChargeEstimateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            rate: String(format: "%.2f", item.rate),
            expiresAt: String(item.expiresAt),
            priority: String(item.priority),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            quantity: String(item.quantity),
            startsAt: String(item.startsAt),
            copay: String(format: "%.2f", item.copay),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeEstimateViews(_ items: [ChargeEstimate]) -> [ChargeEstimateView] {
        var views: [ChargeEstimateView] = []
        for item in items {
            views.append(toChargeEstimateView(item))
        }
        return views
    }

    static func sumChargeEstimateView(_ view: ChargeEstimateView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedRate + Double(parsedExpiresAt) + Double(parsedPriority)
    }
}
