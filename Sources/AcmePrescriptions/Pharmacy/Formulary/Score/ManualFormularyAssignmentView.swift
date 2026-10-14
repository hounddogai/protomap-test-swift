import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual formulary assignment.
    final class ManualFormularyAssignmentView {
        var code: String
        var label: String
        var minimum: String
        var visitMinutesText: String
        var active: String
        var threshold: String
        var summary: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, visitMinutesText: String, active: String, threshold: String, summary: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.visitMinutesText = visitMinutesText
            self.active = active
            self.threshold = threshold
            self.summary = summary
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toManualFormularyAssignmentView(_ item: ManualFormularyAssignment) -> ManualFormularyAssignmentView {
        return ManualFormularyAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            visitMinutesText: String(item.visitMinutes),
            active: "\(item.active)",
            threshold: String(format: "%.2f", item.threshold),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFormularyAssignmentViews(_ items: [ManualFormularyAssignment]) -> [ManualFormularyAssignmentView] {
        var views: [ManualFormularyAssignmentView] = []
        for item in items {
            views.append(toManualFormularyAssignmentView(item))
        }
        return views
    }

    static func sumManualFormularyAssignmentView(_ view: ManualFormularyAssignmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedMinimum + Double(parsedVisitMinutes) + parsedThreshold
    }
}
