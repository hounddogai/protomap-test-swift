import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling bed board draft.
    final class RollingBedBoardDraftView {
        var code: String
        var name: String
        var dosageMgText: String
        var priorityText: String
        var archived: String
        var statusLabel: String

        init(code: String, name: String, dosageMgText: String, priorityText: String, archived: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMgText = dosageMgText
            self.priorityText = priorityText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRollingBedBoardDraftView(_ item: RollingBedBoardDraft) -> RollingBedBoardDraftView {
        return RollingBedBoardDraftView(
            code: item.code,
            name: item.name,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            priorityText: String(item.priority),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingBedBoardDraftViews(_ items: [RollingBedBoardDraft]) -> [RollingBedBoardDraftView] {
        var views: [RollingBedBoardDraftView] = []
        for item in items {
            views.append(toRollingBedBoardDraftView(item))
        }
        return views
    }

    static func sumRollingBedBoardDraftView(_ view: RollingBedBoardDraftView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDosageMg + Double(parsedPriority)
    }
}
