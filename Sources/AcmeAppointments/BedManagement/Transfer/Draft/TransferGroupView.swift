import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer group.
    final class TransferGroupView {
        var code: String
        var name: String
        var pinned: String
        var clinicianID: String
        var unit: String
        var copayText: String
        var statusLabel: String

        init(code: String, name: String, pinned: String, clinicianID: String, unit: String, copayText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.unit = unit
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferGroupView(_ item: TransferGroup) -> TransferGroupView {
        return TransferGroupView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            pinned: "\(item.pinned)",
            clinicianID: item.clinicianID,
            unit: item.unit,
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferGroupViews(_ items: [TransferGroup]) -> [TransferGroupView] {
        var views: [TransferGroupView] = []
        for item in items {
            views.append(toTransferGroupView(item))
        }
        return views
    }

    static func sumTransferGroupView(_ view: TransferGroupView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
