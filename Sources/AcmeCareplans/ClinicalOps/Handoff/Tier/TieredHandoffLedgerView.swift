import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered handoff ledger.
    final class TieredHandoffLedgerView {
        var code: String
        var name: String
        var checksum: String
        var phone: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, name: String, checksum: String, phone: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.phone = phone
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredHandoffLedgerView(_ item: TieredHandoffLedger) -> TieredHandoffLedgerView {
        return TieredHandoffLedgerView(
            code: item.code,
            name: item.name,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            phone: item.phone,
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredHandoffLedgerViews(_ items: [TieredHandoffLedger]) -> [TieredHandoffLedgerView] {
        var views: [TieredHandoffLedgerView] = []
        for item in items {
            views.append(toTieredHandoffLedgerView(item))
        }
        return views
    }

    static func sumTieredHandoffLedgerView(_ view: TieredHandoffLedgerView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
