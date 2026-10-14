import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict care protocol mapping.
    final class StrictCareProtocolMappingView {
        var code: String
        var title: String
        var budget: String
        var wardText: String
        var name: String
        var approved: String
        var channel: String
        var statusLabel: String

        init(code: String, title: String, budget: String, wardText: String, name: String, approved: String, channel: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budget = budget
            self.wardText = wardText
            self.name = name
            self.approved = approved
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCareProtocolMappingView(_ item: StrictCareProtocolMapping) -> StrictCareProtocolMappingView {
        return StrictCareProtocolMappingView(
            code: item.code,
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            wardText: item.ward,
            name: item.name,
            approved: "\(item.approved)",
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCareProtocolMappingViews(_ items: [StrictCareProtocolMapping]) -> [StrictCareProtocolMappingView] {
        var views: [StrictCareProtocolMappingView] = []
        for item in items {
            views.append(toStrictCareProtocolMappingView(item))
        }
        return views
    }

    static func sumStrictCareProtocolMappingView(_ view: StrictCareProtocolMappingView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
