import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped float pool assignment.
    final class CappedFloatPoolAssignmentView {
        var code: String
        var label: String
        var segment: String
        var contactEmail: String
        var priority: String
        var batchSizeText: String
        var title: String
        var specialtyText: String
        var ownerID: String
        var refills: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, segment: String, contactEmail: String, priority: String, batchSizeText: String, title: String, specialtyText: String, ownerID: String, refills: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.contactEmail = contactEmail
            self.priority = priority
            self.batchSizeText = batchSizeText
            self.title = title
            self.specialtyText = specialtyText
            self.ownerID = ownerID
            self.refills = refills
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toCappedFloatPoolAssignmentView(_ item: CappedFloatPoolAssignment) -> CappedFloatPoolAssignmentView {
        return CappedFloatPoolAssignmentView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            segment: item.segment,
            contactEmail: item.contactEmail,
            priority: String(item.priority),
            batchSizeText: String(item.batchSize),
            title: item.title,
            specialtyText: item.specialty,
            ownerID: item.ownerID,
            refills: String(item.refills),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedFloatPoolAssignmentViews(_ items: [CappedFloatPoolAssignment]) -> [CappedFloatPoolAssignmentView] {
        var views: [CappedFloatPoolAssignmentView] = []
        for item in items {
            views.append(toCappedFloatPoolAssignmentView(item))
        }
        return views
    }

    static func sumCappedFloatPoolAssignmentView(_ view: CappedFloatPoolAssignmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedPriority) + Double(parsedBatchSize) + Double(parsedRefills)
    }
}
