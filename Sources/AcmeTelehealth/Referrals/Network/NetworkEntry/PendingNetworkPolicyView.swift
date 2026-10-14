import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending network policy.
    final class PendingNetworkPolicyView {
        var code: String
        var nameText: String
        var timezoneText: String
        var budget: String
        var ratio: String
        var procedureCode: String
        var windowDays: String
        var clinicianIDText: String
        var locale: String
        var statusLabel: String

        init(code: String, nameText: String, timezoneText: String, budget: String, ratio: String, procedureCode: String, windowDays: String, clinicianIDText: String, locale: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.timezoneText = timezoneText
            self.budget = budget
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.clinicianIDText = clinicianIDText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toPendingNetworkPolicyView(_ item: PendingNetworkPolicy) -> PendingNetworkPolicyView {
        return PendingNetworkPolicyView(
            code: item.code,
            nameText: item.name,
            timezoneText: item.timezone,
            budget: String(format: "%.2f", item.budget),
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            windowDays: String(item.windowDays),
            clinicianIDText: item.clinicianID,
            locale: Kit.Text.truncate(item.locale, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingNetworkPolicyViews(_ items: [PendingNetworkPolicy]) -> [PendingNetworkPolicyView] {
        var views: [PendingNetworkPolicyView] = []
        for item in items {
            views.append(toPendingNetworkPolicyView(item))
        }
        return views
    }

    static func sumPendingNetworkPolicyView(_ view: PendingNetworkPolicyView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedBudget + parsedRatio + Double(parsedWindowDays)
    }
}
