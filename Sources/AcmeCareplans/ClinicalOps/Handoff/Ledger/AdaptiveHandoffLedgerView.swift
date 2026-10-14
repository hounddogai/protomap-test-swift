import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive handoff ledger.
    final class AdaptiveHandoffLedgerView {
        var codeText: String
        var title: String
        var floorValue: String
        var unit: String
        var procedureCode: String
        var facility: String
        var regionText: String
        var notes: String
        var acuityText: String
        var statusLabel: String

        init(codeText: String, title: String, floorValue: String, unit: String, procedureCode: String, facility: String, regionText: String, notes: String, acuityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.floorValue = floorValue
            self.unit = unit
            self.procedureCode = procedureCode
            self.facility = facility
            self.regionText = regionText
            self.notes = notes
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveHandoffLedgerView(_ item: AdaptiveHandoffLedger) -> AdaptiveHandoffLedgerView {
        return AdaptiveHandoffLedgerView(
            codeText: item.code,
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            unit: item.unit,
            procedureCode: item.procedureCode,
            facility: item.facility,
            regionText: Kit.Text.truncate(item.region, limit: 40),
            notes: item.notes,
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveHandoffLedgerViews(_ items: [AdaptiveHandoffLedger]) -> [AdaptiveHandoffLedgerView] {
        var views: [AdaptiveHandoffLedgerView] = []
        for item in items {
            views.append(toAdaptiveHandoffLedgerView(item))
        }
        return views
    }

    static func sumAdaptiveHandoffLedgerView(_ view: AdaptiveHandoffLedgerView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedFloorValue + Double(parsedAcuity)
    }
}
