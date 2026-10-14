import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal panel policy.
    final class SeasonalPanelPolicyView {
        var code: String
        var name: String
        var phone: String
        var pinnedText: String
        var country: String
        var priority: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, phone: String, pinnedText: String, country: String, priority: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phone = phone
            self.pinnedText = pinnedText
            self.country = country
            self.priority = priority
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalPanelPolicyView(_ item: SeasonalPanelPolicy) -> SeasonalPanelPolicyView {
        return SeasonalPanelPolicyView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            phone: item.phone,
            pinnedText: "\(item.pinned)",
            country: item.country,
            priority: String(item.priority),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalPanelPolicyViews(_ items: [SeasonalPanelPolicy]) -> [SeasonalPanelPolicyView] {
        var views: [SeasonalPanelPolicyView] = []
        for item in items {
            views.append(toSeasonalPanelPolicyView(item))
        }
        return views
    }

    static func sumSeasonalPanelPolicyView(_ view: SeasonalPanelPolicyView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedPriority) + Double(parsedCreatedAt)
    }
}
