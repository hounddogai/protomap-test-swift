import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist assignment.
    final class WorklistAssignmentView {
        var code: String
        var title: String
        var approved: String
        var checksum: String
        var revision: String
        var quantityText: String
        var statusLabel: String

        init(code: String, title: String, approved: String, checksum: String, revision: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approved = approved
            self.checksum = checksum
            self.revision = revision
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistAssignmentView(_ item: WorklistAssignment) -> WorklistAssignmentView {
        return WorklistAssignmentView(
            code: item.code,
            title: item.title,
            approved: "\(item.approved)",
            checksum: item.checksum,
            revision: String(item.revision),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistAssignmentViews(_ items: [WorklistAssignment]) -> [WorklistAssignmentView] {
        var views: [WorklistAssignmentView] = []
        for item in items {
            views.append(toWorklistAssignmentView(item))
        }
        return views
    }

    static func sumWorklistAssignmentView(_ view: WorklistAssignmentView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRevision) + Double(parsedQuantity)
    }
}
