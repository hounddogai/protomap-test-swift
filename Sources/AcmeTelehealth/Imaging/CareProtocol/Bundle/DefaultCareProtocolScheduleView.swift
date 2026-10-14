import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default care protocol schedule.
    final class DefaultCareProtocolScheduleView {
        var codeText: String
        var title: String
        var budget: String
        var category: String
        var ownerIDText: String
        var source: String
        var regionText: String
        var weightText: String
        var statusLabel: String

        init(codeText: String, title: String, budget: String, category: String, ownerIDText: String, source: String, regionText: String, weightText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.budget = budget
            self.category = category
            self.ownerIDText = ownerIDText
            self.source = source
            self.regionText = regionText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolScheduleView(_ item: DefaultCareProtocolSchedule) -> DefaultCareProtocolScheduleView {
        return DefaultCareProtocolScheduleView(
            codeText: item.code,
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            category: Kit.Text.truncate(item.category, limit: 80),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            source: item.source,
            regionText: item.region,
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolScheduleViews(_ items: [DefaultCareProtocolSchedule]) -> [DefaultCareProtocolScheduleView] {
        var views: [DefaultCareProtocolScheduleView] = []
        for item in items {
            views.append(toDefaultCareProtocolScheduleView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolScheduleView(_ view: DefaultCareProtocolScheduleView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedBudget + parsedWeight
    }
}
