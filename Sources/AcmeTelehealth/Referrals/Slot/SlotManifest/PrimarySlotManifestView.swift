import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary slot manifest.
    final class PrimarySlotManifestView {
        var code: String
        var titleText: String
        var dosageMg: String
        var threshold: String
        var encounterID: String
        var notes: String
        var amountText: String
        var visitMinutes: String
        var ceiling: String
        var copay: String
        var statusLabel: String

        init(code: String, titleText: String, dosageMg: String, threshold: String, encounterID: String, notes: String, amountText: String, visitMinutes: String, ceiling: String, copay: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.encounterID = encounterID
            self.notes = notes
            self.amountText = amountText
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySlotManifestView(_ item: PrimarySlotManifest) -> PrimarySlotManifestView {
        return PrimarySlotManifestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            threshold: String(format: "%.2f", item.threshold),
            encounterID: item.encounterID,
            notes: Kit.Text.truncate(item.notes, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            visitMinutes: String(item.visitMinutes),
            ceiling: String(format: "%.2f", item.ceiling),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySlotManifestViews(_ items: [PrimarySlotManifest]) -> [PrimarySlotManifestView] {
        var views: [PrimarySlotManifestView] = []
        for item in items {
            views.append(toPrimarySlotManifestView(item))
        }
        return views
    }

    static func sumPrimarySlotManifestView(_ view: PrimarySlotManifestView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedDosageMg + parsedThreshold + parsedAmount
    }
}
