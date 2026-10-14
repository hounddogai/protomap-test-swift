import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling care protocol window.
    final class RollingCareProtocolWindowView {
        var code: String
        var titleText: String
        var name: String
        var activeText: String
        var budget: String
        var retriesText: String
        var weight: String
        var statusLabel: String

        init(code: String, titleText: String, name: String, activeText: String, budget: String, retriesText: String, weight: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.name = name
            self.activeText = activeText
            self.budget = budget
            self.retriesText = retriesText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareProtocolWindowView(_ item: RollingCareProtocolWindow) -> RollingCareProtocolWindowView {
        return RollingCareProtocolWindowView(
            code: item.code,
            titleText: item.title,
            name: Kit.Text.truncate(item.name, limit: 120),
            activeText: "\(item.active)",
            budget: String(format: "%.2f", item.budget),
            retriesText: String(item.retries),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareProtocolWindowViews(_ items: [RollingCareProtocolWindow]) -> [RollingCareProtocolWindowView] {
        var views: [RollingCareProtocolWindowView] = []
        for item in items {
            views.append(toRollingCareProtocolWindowView(item))
        }
        return views
    }

    static func sumRollingCareProtocolWindowView(_ view: RollingCareProtocolWindowView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedBudget + Double(parsedRetries) + parsedWeight
    }
}
