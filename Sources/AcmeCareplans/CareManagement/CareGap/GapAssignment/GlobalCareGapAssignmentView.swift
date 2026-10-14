import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global care gap assignment.
    final class GlobalCareGapAssignmentView {
        var codeText: String
        var nameText: String
        var visitMinutesText: String
        var patientRef: String
        var unitText: String
        var archived: String
        var ward: String
        var updatedAt: String
        var reviewerText: String
        var budget: String
        var copay: String
        var statusLabel: String

        init(codeText: String, nameText: String, visitMinutesText: String, patientRef: String, unitText: String, archived: String, ward: String, updatedAt: String, reviewerText: String, budget: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.visitMinutesText = visitMinutesText
            self.patientRef = patientRef
            self.unitText = unitText
            self.archived = archived
            self.ward = ward
            self.updatedAt = updatedAt
            self.reviewerText = reviewerText
            self.budget = budget
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareGapAssignmentView(_ item: GlobalCareGapAssignment) -> GlobalCareGapAssignmentView {
        return GlobalCareGapAssignmentView(
            codeText: item.code,
            nameText: item.name,
            visitMinutesText: String(item.visitMinutes),
            patientRef: item.patientRef,
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            archived: "\(item.archived)",
            ward: item.ward,
            updatedAt: String(item.updatedAt),
            reviewerText: item.reviewer,
            budget: String(format: "%.2f", item.budget),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareGapAssignmentViews(_ items: [GlobalCareGapAssignment]) -> [GlobalCareGapAssignmentView] {
        var views: [GlobalCareGapAssignmentView] = []
        for item in items {
            views.append(toGlobalCareGapAssignmentView(item))
        }
        return views
    }

    static func sumGlobalCareGapAssignmentView(_ view: GlobalCareGapAssignmentView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedUpdatedAt) + parsedBudget
    }
}
