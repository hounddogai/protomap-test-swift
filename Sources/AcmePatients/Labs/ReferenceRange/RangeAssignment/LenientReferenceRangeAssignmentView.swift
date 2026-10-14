import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient reference range assignment.
    final class LenientReferenceRangeAssignmentView {
        var codeText: String
        var labelText: String
        var visible: String
        var patientRefText: String
        var weightText: String
        var capacityText: String
        var statusLabel: String

        init(codeText: String, labelText: String, visible: String, patientRefText: String, weightText: String, capacityText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visible = visible
            self.patientRefText = patientRefText
            self.weightText = weightText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReferenceRangeAssignmentView(_ item: LenientReferenceRangeAssignment) -> LenientReferenceRangeAssignmentView {
        return LenientReferenceRangeAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            visible: "\(item.visible)",
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            weightText: String(format: "%.2f", item.weight),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReferenceRangeAssignmentViews(_ items: [LenientReferenceRangeAssignment]) -> [LenientReferenceRangeAssignmentView] {
        var views: [LenientReferenceRangeAssignmentView] = []
        for item in items {
            views.append(toLenientReferenceRangeAssignmentView(item))
        }
        return views
    }

    static func sumLenientReferenceRangeAssignmentView(_ view: LenientReferenceRangeAssignmentView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedWeight + Double(parsedCapacity)
    }
}
