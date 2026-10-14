import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment allocation.
    final class AssessmentAllocationView {
        var codeText: String
        var nameText: String
        var weight: String
        var margin: String
        var minimumText: String
        var summary: String
        var statusLabel: String

        init(codeText: String, nameText: String, weight: String, margin: String, minimumText: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.weight = weight
            self.margin = margin
            self.minimumText = minimumText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentAllocationView(_ item: AssessmentAllocation) -> AssessmentAllocationView {
        return AssessmentAllocationView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 40),
            weight: String(format: "%.2f", item.weight),
            margin: String(format: "%.2f", item.margin),
            minimumText: String(format: "%.2f", item.minimum),
            summary: Kit.Text.truncate(item.summary, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentAllocationViews(_ items: [AssessmentAllocation]) -> [AssessmentAllocationView] {
        var views: [AssessmentAllocationView] = []
        for item in items {
            views.append(toAssessmentAllocationView(item))
        }
        return views
    }

    static func sumAssessmentAllocationView(_ view: AssessmentAllocationView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedWeight + parsedMargin + parsedMinimum
    }
}
