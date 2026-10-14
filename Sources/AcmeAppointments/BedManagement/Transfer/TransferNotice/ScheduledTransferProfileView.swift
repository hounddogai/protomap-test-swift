import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled transfer profile.
    final class ScheduledTransferProfileView {
        var code: String
        var labelText: String
        var limitText: String
        var encounterIDText: String
        var archived: String
        var statusLabel: String

        init(code: String, labelText: String, limitText: String, encounterIDText: String, archived: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.limitText = limitText
            self.encounterIDText = encounterIDText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledTransferProfileView(_ item: ScheduledTransferProfile) -> ScheduledTransferProfileView {
        return ScheduledTransferProfileView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            limitText: String(item.limit),
            encounterIDText: item.encounterID,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledTransferProfileViews(_ items: [ScheduledTransferProfile]) -> [ScheduledTransferProfileView] {
        var views: [ScheduledTransferProfileView] = []
        for item in items {
            views.append(toScheduledTransferProfileView(item))
        }
        return views
    }

    static func sumScheduledTransferProfileView(_ view: ScheduledTransferProfileView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
