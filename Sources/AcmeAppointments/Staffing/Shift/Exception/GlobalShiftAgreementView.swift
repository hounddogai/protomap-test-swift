import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global shift agreement.
    final class GlobalShiftAgreementView {
        var code: String
        var nameText: String
        var amount: String
        var sequence: String
        var thresholdText: String
        var unit: String
        var refills: String
        var procedureCodeText: String
        var archived: String
        var statusLabel: String

        init(code: String, nameText: String, amount: String, sequence: String, thresholdText: String, unit: String, refills: String, procedureCodeText: String, archived: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.amount = amount
            self.sequence = sequence
            self.thresholdText = thresholdText
            self.unit = unit
            self.refills = refills
            self.procedureCodeText = procedureCodeText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalShiftAgreementView(_ item: GlobalShiftAgreement) -> GlobalShiftAgreementView {
        return GlobalShiftAgreementView(
            code: item.code,
            nameText: item.name,
            amount: String(format: "%.2f", item.amount),
            sequence: String(item.sequence),
            thresholdText: String(format: "%.2f", item.threshold),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            refills: String(item.refills),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalShiftAgreementViews(_ items: [GlobalShiftAgreement]) -> [GlobalShiftAgreementView] {
        var views: [GlobalShiftAgreementView] = []
        for item in items {
            views.append(toGlobalShiftAgreementView(item))
        }
        return views
    }

    static func sumGlobalShiftAgreementView(_ view: GlobalShiftAgreementView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedAmount + Double(parsedSequence) + parsedThreshold
    }
}
