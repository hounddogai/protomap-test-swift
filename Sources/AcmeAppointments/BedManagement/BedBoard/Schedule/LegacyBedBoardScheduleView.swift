import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy bed board schedule.
    final class LegacyBedBoardScheduleView {
        var codeText: String
        var nameText: String
        var priority: String
        var batchSize: String
        var country: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, nameText: String, priority: String, batchSize: String, country: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.priority = priority
            self.batchSize = batchSize
            self.country = country
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyBedBoardScheduleView(_ item: LegacyBedBoardSchedule) -> LegacyBedBoardScheduleView {
        return LegacyBedBoardScheduleView(
            codeText: item.code,
            nameText: item.name,
            priority: String(item.priority),
            batchSize: String(item.batchSize),
            country: Kit.Text.truncate(item.country, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyBedBoardScheduleViews(_ items: [LegacyBedBoardSchedule]) -> [LegacyBedBoardScheduleView] {
        var views: [LegacyBedBoardScheduleView] = []
        for item in items {
            views.append(toLegacyBedBoardScheduleView(item))
        }
        return views
    }

    static func sumLegacyBedBoardScheduleView(_ view: LegacyBedBoardScheduleView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedPriority) + Double(parsedBatchSize) + parsedCeiling
    }
}
