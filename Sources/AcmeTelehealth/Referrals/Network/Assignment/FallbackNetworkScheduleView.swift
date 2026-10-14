import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback network schedule.
    final class FallbackNetworkScheduleView {
        var code: String
        var name: String
        var country: String
        var minimum: String
        var endsAt: String
        var priority: String
        var discount: String
        var acuity: String
        var updatedAt: String
        var contactEmail: String
        var version: String
        var statusLabel: String

        init(code: String, name: String, country: String, minimum: String, endsAt: String, priority: String, discount: String, acuity: String, updatedAt: String, contactEmail: String, version: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.country = country
            self.minimum = minimum
            self.endsAt = endsAt
            self.priority = priority
            self.discount = discount
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackNetworkScheduleView(_ item: FallbackNetworkSchedule) -> FallbackNetworkScheduleView {
        return FallbackNetworkScheduleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            country: Kit.Text.truncate(item.country, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            endsAt: String(item.endsAt),
            priority: String(item.priority),
            discount: String(format: "%.2f", item.discount),
            acuity: String(item.acuity),
            updatedAt: String(item.updatedAt),
            contactEmail: item.contactEmail,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackNetworkScheduleViews(_ items: [FallbackNetworkSchedule]) -> [FallbackNetworkScheduleView] {
        var views: [FallbackNetworkScheduleView] = []
        for item in items {
            views.append(toFallbackNetworkScheduleView(item))
        }
        return views
    }

    static func sumFallbackNetworkScheduleView(_ view: FallbackNetworkScheduleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMinimum + Double(parsedEndsAt) + Double(parsedPriority)
    }
}
