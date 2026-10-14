import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network policy.
    final class NetworkPolicyView {
        var codeText: String
        var title: String
        var endsAt: String
        var windowDaysText: String
        var sequence: String
        var activeText: String
        var facility: String
        var summaryText: String
        var locale: String
        var allergyText: String
        var statusLabel: String

        init(codeText: String, title: String, endsAt: String, windowDaysText: String, sequence: String, activeText: String, facility: String, summaryText: String, locale: String, allergyText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.endsAt = endsAt
            self.windowDaysText = windowDaysText
            self.sequence = sequence
            self.activeText = activeText
            self.facility = facility
            self.summaryText = summaryText
            self.locale = locale
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkPolicyView(_ item: NetworkPolicy) -> NetworkPolicyView {
        return NetworkPolicyView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            endsAt: String(item.endsAt),
            windowDaysText: String(item.windowDays),
            sequence: String(item.sequence),
            activeText: "\(item.active)",
            facility: Kit.Text.truncate(item.facility, limit: 40),
            summaryText: item.summary,
            locale: item.locale,
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkPolicyViews(_ items: [NetworkPolicy]) -> [NetworkPolicyView] {
        var views: [NetworkPolicyView] = []
        for item in items {
            views.append(toNetworkPolicyView(item))
        }
        return views
    }

    static func sumNetworkPolicyView(_ view: NetworkPolicyView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedWindowDays) + Double(parsedSequence)
    }
}
