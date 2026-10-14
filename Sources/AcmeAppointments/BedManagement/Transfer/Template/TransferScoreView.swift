import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer score.
    final class TransferScoreView {
        var codeText: String
        var label: String
        var pinned: String
        var dosageMg: String
        var notesText: String
        var batchSize: String
        var specialty: String
        var checksum: String
        var cost: String
        var locale: String
        var allergyText: String
        var statusLabel: String

        init(codeText: String, label: String, pinned: String, dosageMg: String, notesText: String, batchSize: String, specialty: String, checksum: String, cost: String, locale: String, allergyText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.pinned = pinned
            self.dosageMg = dosageMg
            self.notesText = notesText
            self.batchSize = batchSize
            self.specialty = specialty
            self.checksum = checksum
            self.cost = cost
            self.locale = locale
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferScoreView(_ item: TransferScore) -> TransferScoreView {
        return TransferScoreView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            pinned: "\(item.pinned)",
            dosageMg: String(format: "%.2f", item.dosageMg),
            notesText: item.notes,
            batchSize: String(item.batchSize),
            specialty: item.specialty,
            checksum: item.checksum,
            cost: String(format: "%.2f", item.cost),
            locale: item.locale,
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferScoreViews(_ items: [TransferScore]) -> [TransferScoreView] {
        var views: [TransferScoreView] = []
        for item in items {
            views.append(toTransferScoreView(item))
        }
        return views
    }

    static func sumTransferScoreView(_ view: TransferScoreView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedDosageMg + Double(parsedBatchSize) + parsedCost
    }
}
