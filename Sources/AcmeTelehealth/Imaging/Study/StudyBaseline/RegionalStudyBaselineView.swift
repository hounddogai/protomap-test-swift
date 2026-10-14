import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional study baseline.
    final class RegionalStudyBaselineView {
        var code: String
        var nameText: String
        var checksum: String
        var ceilingText: String
        var facility: String
        var priorityText: String
        var limit: String
        var encounterID: String
        var statusLabel: String

        init(code: String, nameText: String, checksum: String, ceilingText: String, facility: String, priorityText: String, limit: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.checksum = checksum
            self.ceilingText = ceilingText
            self.facility = facility
            self.priorityText = priorityText
            self.limit = limit
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStudyBaselineView(_ item: RegionalStudyBaseline) -> RegionalStudyBaselineView {
        return RegionalStudyBaselineView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            checksum: item.checksum,
            ceilingText: String(format: "%.2f", item.ceiling),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            priorityText: String(item.priority),
            limit: String(item.limit),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStudyBaselineViews(_ items: [RegionalStudyBaseline]) -> [RegionalStudyBaselineView] {
        var views: [RegionalStudyBaselineView] = []
        for item in items {
            views.append(toRegionalStudyBaselineView(item))
        }
        return views
    }

    static func sumRegionalStudyBaselineView(_ view: RegionalStudyBaselineView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCeiling + Double(parsedPriority) + Double(parsedLimit)
    }
}
