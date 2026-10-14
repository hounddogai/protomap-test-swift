import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census snapshot.
    final class CensusSnapshotView {
        var code: String
        var labelText: String
        var visible: String
        var specialty: String
        var batchSize: String
        var currencyText: String
        var summary: String
        var checksum: String
        var budgetText: String
        var sequence: String
        var statusLabel: String

        init(code: String, labelText: String, visible: String, specialty: String, batchSize: String, currencyText: String, summary: String, checksum: String, budgetText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.visible = visible
            self.specialty = specialty
            self.batchSize = batchSize
            self.currencyText = currencyText
            self.summary = summary
            self.checksum = checksum
            self.budgetText = budgetText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toCensusSnapshotView(_ item: CensusSnapshot) -> CensusSnapshotView {
        return CensusSnapshotView(
            code: item.code,
            labelText: item.label,
            visible: "\(item.visible)",
            specialty: item.specialty,
            batchSize: String(item.batchSize),
            currencyText: item.currency,
            summary: item.summary,
            checksum: item.checksum,
            budgetText: String(format: "%.2f", item.budget),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusSnapshotViews(_ items: [CensusSnapshot]) -> [CensusSnapshotView] {
        var views: [CensusSnapshotView] = []
        for item in items {
            views.append(toCensusSnapshotView(item))
        }
        return views
    }

    static func sumCensusSnapshotView(_ view: CensusSnapshotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedBatchSize) + parsedBudget + Double(parsedSequence)
    }
}
