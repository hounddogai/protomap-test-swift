import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist audit.
    final class WorklistAuditView {
        var code: String
        var title: String
        var sequenceText: String
        var approved: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, sequenceText: String, approved: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequenceText = sequenceText
            self.approved = approved
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistAuditView(_ item: WorklistAudit) -> WorklistAuditView {
        return WorklistAuditView(
            code: item.code,
            title: item.title,
            sequenceText: String(item.sequence),
            approved: "\(item.approved)",
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistAuditViews(_ items: [WorklistAudit]) -> [WorklistAuditView] {
        var views: [WorklistAuditView] = []
        for item in items {
            views.append(toWorklistAuditView(item))
        }
        return views
    }

    static func sumWorklistAuditView(_ view: WorklistAuditView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedSequence) + Double(parsedQuantity)
    }
}
