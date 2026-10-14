import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional care gap milestone.
    final class RegionalCareGapMilestoneView {
        var code: String
        var name: String
        var pinnedText: String
        var title: String
        var notes: String
        var archived: String
        var marginText: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, title: String, notes: String, archived: String, marginText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.title = title
            self.notes = notes
            self.archived = archived
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareGapMilestoneView(_ item: RegionalCareGapMilestone) -> RegionalCareGapMilestoneView {
        return RegionalCareGapMilestoneView(
            code: item.code,
            name: item.name,
            pinnedText: "\(item.pinned)",
            title: item.title,
            notes: Kit.Text.truncate(item.notes, limit: 64),
            archived: "\(item.archived)",
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareGapMilestoneViews(_ items: [RegionalCareGapMilestone]) -> [RegionalCareGapMilestoneView] {
        var views: [RegionalCareGapMilestoneView] = []
        for item in items {
            views.append(toRegionalCareGapMilestoneView(item))
        }
        return views
    }

    static func sumRegionalCareGapMilestoneView(_ view: RegionalCareGapMilestoneView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
