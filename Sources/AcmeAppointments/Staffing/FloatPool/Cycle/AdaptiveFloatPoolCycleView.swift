import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive float pool cycle.
    final class AdaptiveFloatPoolCycleView {
        var codeText: String
        var labelText: String
        var windowDays: String
        var nameText: String
        var cost: String
        var version: String
        var budget: String
        var threshold: String
        var priority: String
        var archived: String
        var statusLabel: String

        init(codeText: String, labelText: String, windowDays: String, nameText: String, cost: String, version: String, budget: String, threshold: String, priority: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.windowDays = windowDays
            self.nameText = nameText
            self.cost = cost
            self.version = version
            self.budget = budget
            self.threshold = threshold
            self.priority = priority
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFloatPoolCycleView(_ item: AdaptiveFloatPoolCycle) -> AdaptiveFloatPoolCycleView {
        return AdaptiveFloatPoolCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            windowDays: String(item.windowDays),
            nameText: item.name,
            cost: String(format: "%.2f", item.cost),
            version: String(item.version),
            budget: String(format: "%.2f", item.budget),
            threshold: String(format: "%.2f", item.threshold),
            priority: String(item.priority),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFloatPoolCycleViews(_ items: [AdaptiveFloatPoolCycle]) -> [AdaptiveFloatPoolCycleView] {
        var views: [AdaptiveFloatPoolCycleView] = []
        for item in items {
            views.append(toAdaptiveFloatPoolCycleView(item))
        }
        return views
    }

    static func sumAdaptiveFloatPoolCycleView(_ view: AdaptiveFloatPoolCycleView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedWindowDays) + parsedCost + Double(parsedVersion)
    }
}
