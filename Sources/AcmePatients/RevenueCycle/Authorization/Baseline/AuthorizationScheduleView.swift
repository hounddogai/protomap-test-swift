import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization schedule.
    final class AuthorizationScheduleView {
        var codeText: String
        var label: String
        var segment: String
        var ward: String
        var allergyText: String
        var budget: String
        var rate: String
        var pinned: String
        var statusLabel: String

        init(codeText: String, label: String, segment: String, ward: String, allergyText: String, budget: String, rate: String, pinned: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.segment = segment
            self.ward = ward
            self.allergyText = allergyText
            self.budget = budget
            self.rate = rate
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationScheduleView(_ item: AuthorizationSchedule) -> AuthorizationScheduleView {
        return AuthorizationScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            ward: item.ward,
            allergyText: item.allergy,
            budget: String(format: "%.2f", item.budget),
            rate: String(format: "%.2f", item.rate),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationScheduleViews(_ items: [AuthorizationSchedule]) -> [AuthorizationScheduleView] {
        var views: [AuthorizationScheduleView] = []
        for item in items {
            views.append(toAuthorizationScheduleView(item))
        }
        return views
    }

    static func sumAuthorizationScheduleView(_ view: AuthorizationScheduleView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedBudget + parsedRate
    }
}
