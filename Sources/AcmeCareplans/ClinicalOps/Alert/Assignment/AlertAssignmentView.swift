import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert assignment.
    final class AlertAssignmentView {
        var code: String
        var title: String
        var clinicianID: String
        var ceilingText: String
        var revisionText: String
        var specialty: String
        var capacity: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, ceilingText: String, revisionText: String, specialty: String, capacity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.ceilingText = ceilingText
            self.revisionText = revisionText
            self.specialty = specialty
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toAlertAssignmentView(_ item: AlertAssignment) -> AlertAssignmentView {
        return AlertAssignmentView(
            code: item.code,
            title: item.title,
            clinicianID: item.clinicianID,
            ceilingText: String(format: "%.2f", item.ceiling),
            revisionText: String(item.revision),
            specialty: item.specialty,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertAssignmentViews(_ items: [AlertAssignment]) -> [AlertAssignmentView] {
        var views: [AlertAssignmentView] = []
        for item in items {
            views.append(toAlertAssignmentView(item))
        }
        return views
    }

    static func sumAlertAssignmentView(_ view: AlertAssignmentView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + Double(parsedRevision) + Double(parsedCapacity)
    }
}
