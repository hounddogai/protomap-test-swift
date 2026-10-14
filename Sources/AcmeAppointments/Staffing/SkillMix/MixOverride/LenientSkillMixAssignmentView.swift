import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient skill mix assignment.
    final class LenientSkillMixAssignmentView {
        var code: String
        var title: String
        var capacity: String
        var unit: String
        var patientRef: String
        var ownerID: String
        var batchSize: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, unit: String, patientRef: String, ownerID: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.unit = unit
            self.patientRef = patientRef
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toLenientSkillMixAssignmentView(_ item: LenientSkillMixAssignment) -> LenientSkillMixAssignmentView {
        return LenientSkillMixAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            capacity: String(item.capacity),
            unit: item.unit,
            patientRef: item.patientRef,
            ownerID: item.ownerID,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientSkillMixAssignmentViews(_ items: [LenientSkillMixAssignment]) -> [LenientSkillMixAssignmentView] {
        var views: [LenientSkillMixAssignmentView] = []
        for item in items {
            views.append(toLenientSkillMixAssignmentView(item))
        }
        return views
    }

    static func sumLenientSkillMixAssignmentView(_ view: LenientSkillMixAssignmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedCapacity) + Double(parsedBatchSize)
    }
}
