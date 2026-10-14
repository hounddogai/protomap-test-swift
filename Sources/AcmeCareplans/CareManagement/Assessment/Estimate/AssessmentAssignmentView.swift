import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment assignment.
    final class AssessmentAssignmentView {
        var code: String
        var titleText: String
        var procedureCode: String
        var weight: String
        var maximum: String
        var statusLabel: String

        init(code: String, titleText: String, procedureCode: String, weight: String, maximum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.procedureCode = procedureCode
            self.weight = weight
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentAssignmentView(_ item: AssessmentAssignment) -> AssessmentAssignmentView {
        return AssessmentAssignmentView(
            code: item.code,
            titleText: item.title,
            procedureCode: item.procedureCode,
            weight: String(format: "%.2f", item.weight),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentAssignmentViews(_ items: [AssessmentAssignment]) -> [AssessmentAssignmentView] {
        var views: [AssessmentAssignmentView] = []
        for item in items {
            views.append(toAssessmentAssignmentView(item))
        }
        return views
    }

    static func sumAssessmentAssignmentView(_ view: AssessmentAssignmentView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedWeight + parsedMaximum
    }
}
