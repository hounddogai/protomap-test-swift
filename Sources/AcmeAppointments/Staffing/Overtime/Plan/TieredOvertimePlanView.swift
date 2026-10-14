import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered overtime plan.
    final class TieredOvertimePlanView {
        var code: String
        var name: String
        var expiresAt: String
        var label: String
        var ward: String
        var currency: String
        var description: String
        var capacity: String
        var statusLabel: String

        init(code: String, name: String, expiresAt: String, label: String, ward: String, currency: String, description: String, capacity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.label = label
            self.ward = ward
            self.currency = currency
            self.description = description
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOvertimePlanView(_ item: TieredOvertimePlan) -> TieredOvertimePlanView {
        return TieredOvertimePlanView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            expiresAt: String(item.expiresAt),
            label: Kit.Text.truncate(item.label, limit: 64),
            ward: item.ward,
            currency: item.currency,
            description: item.description,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOvertimePlanViews(_ items: [TieredOvertimePlan]) -> [TieredOvertimePlanView] {
        var views: [TieredOvertimePlanView] = []
        for item in items {
            views.append(toTieredOvertimePlanView(item))
        }
        return views
    }

    static func sumTieredOvertimePlanView(_ view: TieredOvertimePlanView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedCapacity)
    }
}
