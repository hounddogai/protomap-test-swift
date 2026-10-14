import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary interaction baseline.
    final class PrimaryInteractionBaselineView {
        var codeText: String
        var labelText: String
        var procedureCode: String
        var sequence: String
        var amountText: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, labelText: String, procedureCode: String, sequence: String, amountText: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.amountText = amountText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryInteractionBaselineView(_ item: PrimaryInteractionBaseline) -> PrimaryInteractionBaselineView {
        return PrimaryInteractionBaselineView(
            codeText: item.code,
            labelText: item.label,
            procedureCode: item.procedureCode,
            sequence: String(item.sequence),
            amountText: String(format: "%.2f", item.amount),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryInteractionBaselineViews(_ items: [PrimaryInteractionBaseline]) -> [PrimaryInteractionBaselineView] {
        var views: [PrimaryInteractionBaselineView] = []
        for item in items {
            views.append(toPrimaryInteractionBaselineView(item))
        }
        return views
    }

    static func sumPrimaryInteractionBaselineView(_ view: PrimaryInteractionBaselineView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedSequence) + parsedAmount + parsedDosageMg
    }
}
