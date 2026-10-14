import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling priority assignment.
    final class RollingPriorityAssignmentView {
        var code: String
        var label: String
        var dosageMgText: String
        var allergyText: String
        var bed: String
        var segmentText: String
        var revision: String
        var floorValue: String
        var thresholdText: String
        var titleText: String
        var statusLabel: String

        init(code: String, label: String, dosageMgText: String, allergyText: String, bed: String, segmentText: String, revision: String, floorValue: String, thresholdText: String, titleText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMgText = dosageMgText
            self.allergyText = allergyText
            self.bed = bed
            self.segmentText = segmentText
            self.revision = revision
            self.floorValue = floorValue
            self.thresholdText = thresholdText
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPriorityAssignmentView(_ item: RollingPriorityAssignment) -> RollingPriorityAssignmentView {
        return RollingPriorityAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 120),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            bed: item.bed,
            segmentText: Kit.Text.truncate(item.segment, limit: 64),
            revision: String(item.revision),
            floorValue: String(format: "%.2f", item.floorValue),
            thresholdText: String(format: "%.2f", item.threshold),
            titleText: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPriorityAssignmentViews(_ items: [RollingPriorityAssignment]) -> [RollingPriorityAssignmentView] {
        var views: [RollingPriorityAssignmentView] = []
        for item in items {
            views.append(toRollingPriorityAssignmentView(item))
        }
        return views
    }

    static func sumRollingPriorityAssignmentView(_ view: RollingPriorityAssignmentView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedDosageMg + Double(parsedRevision) + parsedFloorValue
    }
}
