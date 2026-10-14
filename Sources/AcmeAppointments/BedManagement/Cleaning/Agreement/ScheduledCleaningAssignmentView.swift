import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled cleaning assignment.
    final class ScheduledCleaningAssignmentView {
        var code: String
        var nameText: String
        var copayText: String
        var budgetText: String
        var phone: String
        var allergy: String
        var visitMinutesText: String
        var dosageMgText: String
        var description: String
        var limit: String
        var statusLabel: String

        init(code: String, nameText: String, copayText: String, budgetText: String, phone: String, allergy: String, visitMinutesText: String, dosageMgText: String, description: String, limit: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.copayText = copayText
            self.budgetText = budgetText
            self.phone = phone
            self.allergy = allergy
            self.visitMinutesText = visitMinutesText
            self.dosageMgText = dosageMgText
            self.description = description
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCleaningAssignmentView(_ item: ScheduledCleaningAssignment) -> ScheduledCleaningAssignmentView {
        return ScheduledCleaningAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            copayText: String(format: "%.2f", item.copay),
            budgetText: String(format: "%.2f", item.budget),
            phone: item.phone,
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            visitMinutesText: String(item.visitMinutes),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            description: item.description,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCleaningAssignmentViews(_ items: [ScheduledCleaningAssignment]) -> [ScheduledCleaningAssignmentView] {
        var views: [ScheduledCleaningAssignmentView] = []
        for item in items {
            views.append(toScheduledCleaningAssignmentView(item))
        }
        return views
    }

    static func sumScheduledCleaningAssignmentView(_ view: ScheduledCleaningAssignmentView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedCopay + parsedBudget + Double(parsedVisitMinutes)
    }
}
