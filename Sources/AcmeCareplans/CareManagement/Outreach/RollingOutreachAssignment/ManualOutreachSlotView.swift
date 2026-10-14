import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual outreach slot.
    final class ManualOutreachSlotView {
        var code: String
        var name: String
        var limit: String
        var archivedText: String
        var externalRef: String
        var score: String
        var encounterID: String
        var visibleText: String
        var wardText: String
        var approvedText: String
        var statusLabel: String

        init(code: String, name: String, limit: String, archivedText: String, externalRef: String, score: String, encounterID: String, visibleText: String, wardText: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.archivedText = archivedText
            self.externalRef = externalRef
            self.score = score
            self.encounterID = encounterID
            self.visibleText = visibleText
            self.wardText = wardText
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toManualOutreachSlotView(_ item: ManualOutreachSlot) -> ManualOutreachSlotView {
        return ManualOutreachSlotView(
            code: item.code,
            name: item.name,
            limit: String(item.limit),
            archivedText: "\(item.archived)",
            externalRef: item.externalRef,
            score: String(format: "%.2f", item.score),
            encounterID: item.encounterID,
            visibleText: "\(item.visible)",
            wardText: item.ward,
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualOutreachSlotViews(_ items: [ManualOutreachSlot]) -> [ManualOutreachSlotView] {
        var views: [ManualOutreachSlotView] = []
        for item in items {
            views.append(toManualOutreachSlotView(item))
        }
        return views
    }

    static func sumManualOutreachSlotView(_ view: ManualOutreachSlotView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedLimit) + parsedScore
    }
}
