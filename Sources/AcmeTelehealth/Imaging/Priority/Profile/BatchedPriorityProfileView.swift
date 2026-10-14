import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched priority profile.
    final class BatchedPriorityProfileView {
        var code: String
        var title: String
        var sequence: String
        var patientRef: String
        var amountText: String
        var procedureCode: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, sequence: String, patientRef: String, amountText: String, procedureCode: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.patientRef = patientRef
            self.amountText = amountText
            self.procedureCode = procedureCode
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedPriorityProfileView(_ item: BatchedPriorityProfile) -> BatchedPriorityProfileView {
        return BatchedPriorityProfileView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            sequence: String(item.sequence),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            procedureCode: item.procedureCode,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedPriorityProfileViews(_ items: [BatchedPriorityProfile]) -> [BatchedPriorityProfileView] {
        var views: [BatchedPriorityProfileView] = []
        for item in items {
            views.append(toBatchedPriorityProfileView(item))
        }
        return views
    }

    static func sumBatchedPriorityProfileView(_ view: BatchedPriorityProfileView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedSequence) + parsedAmount + Double(parsedRefills)
    }
}
