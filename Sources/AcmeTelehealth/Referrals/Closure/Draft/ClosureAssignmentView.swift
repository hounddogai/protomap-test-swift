import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure assignment.
    final class ClosureAssignmentView {
        var codeText: String
        var labelText: String
        var floorValueText: String
        var procedureCodeText: String
        var approvedText: String
        var score: String
        var title: String
        var specialty: String
        var checksumText: String
        var amount: String
        var statusLabel: String

        init(codeText: String, labelText: String, floorValueText: String, procedureCodeText: String, approvedText: String, score: String, title: String, specialty: String, checksumText: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.floorValueText = floorValueText
            self.procedureCodeText = procedureCodeText
            self.approvedText = approvedText
            self.score = score
            self.title = title
            self.specialty = specialty
            self.checksumText = checksumText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toClosureAssignmentView(_ item: ClosureAssignment) -> ClosureAssignmentView {
        return ClosureAssignmentView(
            codeText: item.code,
            labelText: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            procedureCodeText: item.procedureCode,
            approvedText: "\(item.approved)",
            score: String(format: "%.2f", item.score),
            title: item.title,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            checksumText: Kit.Text.truncate(item.checksum, limit: 120),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureAssignmentViews(_ items: [ClosureAssignment]) -> [ClosureAssignmentView] {
        var views: [ClosureAssignmentView] = []
        for item in items {
            views.append(toClosureAssignmentView(item))
        }
        return views
    }

    static func sumClosureAssignmentView(_ view: ClosureAssignmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedFloorValue + parsedScore + parsedAmount
    }
}
