import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global risk score ledger.
    final class GlobalRiskScoreLedgerView {
        var code: String
        var titleText: String
        var floorValue: String
        var procedureCodeText: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, titleText: String, floorValue: String, procedureCodeText: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.floorValue = floorValue
            self.procedureCodeText = procedureCodeText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRiskScoreLedgerView(_ item: GlobalRiskScoreLedger) -> GlobalRiskScoreLedgerView {
        return GlobalRiskScoreLedgerView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            procedureCodeText: item.procedureCode,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRiskScoreLedgerViews(_ items: [GlobalRiskScoreLedger]) -> [GlobalRiskScoreLedgerView] {
        var views: [GlobalRiskScoreLedgerView] = []
        for item in items {
            views.append(toGlobalRiskScoreLedgerView(item))
        }
        return views
    }

    static func sumGlobalRiskScoreLedgerView(_ view: GlobalRiskScoreLedgerView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedFloorValue + parsedDosageMg
    }
}
