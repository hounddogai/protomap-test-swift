import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement draft.
    final class StatementDraftView {
        var code: String
        var nameText: String
        var patientRefText: String
        var floorValue: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, nameText: String, patientRefText: String, floorValue: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.patientRefText = patientRefText
            self.floorValue = floorValue
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toStatementDraftView(_ item: StatementDraft) -> StatementDraftView {
        return StatementDraftView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementDraftViews(_ items: [StatementDraft]) -> [StatementDraftView] {
        var views: [StatementDraftView] = []
        for item in items {
            views.append(toStatementDraftView(item))
        }
        return views
    }

    static func sumStatementDraftView(_ view: StatementDraftView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedFloorValue + parsedDosageMg
    }
}
