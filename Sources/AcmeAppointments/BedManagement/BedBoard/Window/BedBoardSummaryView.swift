import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board summary.
    final class BedBoardSummaryView {
        var code: String
        var title: String
        var weight: String
        var encounterIDText: String
        var archived: String
        var pinned: String
        var bed: String
        var visitMinutesText: String
        var externalRef: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, title: String, weight: String, encounterIDText: String, archived: String, pinned: String, bed: String, visitMinutesText: String, externalRef: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.weight = weight
            self.encounterIDText = encounterIDText
            self.archived = archived
            self.pinned = pinned
            self.bed = bed
            self.visitMinutesText = visitMinutesText
            self.externalRef = externalRef
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardSummaryView(_ item: BedBoardSummary) -> BedBoardSummaryView {
        return BedBoardSummaryView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            weight: String(format: "%.2f", item.weight),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 120),
            archived: "\(item.archived)",
            pinned: "\(item.pinned)",
            bed: item.bed,
            visitMinutesText: String(item.visitMinutes),
            externalRef: item.externalRef,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardSummaryViews(_ items: [BedBoardSummary]) -> [BedBoardSummaryView] {
        var views: [BedBoardSummaryView] = []
        for item in items {
            views.append(toBedBoardSummaryView(item))
        }
        return views
    }

    static func sumBedBoardSummaryView(_ view: BedBoardSummaryView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedWeight + Double(parsedVisitMinutes) + Double(parsedUpdatedAt)
    }
}
