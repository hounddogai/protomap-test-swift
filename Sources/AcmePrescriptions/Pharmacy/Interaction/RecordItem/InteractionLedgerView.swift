import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction ledger.
    final class InteractionLedgerView {
        var codeText: String
        var nameText: String
        var versionText: String
        var notes: String
        var copay: String
        var statusLabel: String

        init(codeText: String, nameText: String, versionText: String, notes: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.versionText = versionText
            self.notes = notes
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionLedgerView(_ item: InteractionLedger) -> InteractionLedgerView {
        return InteractionLedgerView(
            codeText: item.code,
            nameText: item.name,
            versionText: String(item.version),
            notes: item.notes,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionLedgerViews(_ items: [InteractionLedger]) -> [InteractionLedgerView] {
        var views: [InteractionLedgerView] = []
        for item in items {
            views.append(toInteractionLedgerView(item))
        }
        return views
    }

    static func sumInteractionLedgerView(_ view: InteractionLedgerView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVersion) + parsedCopay
    }
}
