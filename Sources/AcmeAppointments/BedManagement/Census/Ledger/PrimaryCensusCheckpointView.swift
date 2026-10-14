import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary census checkpoint.
    final class PrimaryCensusCheckpointView {
        var code: String
        var title: String
        var copayText: String
        var segment: String
        var dosageMg: String
        var capacityText: String
        var budget: String
        var rate: String
        var batchSize: String
        var statusLabel: String

        init(code: String, title: String, copayText: String, segment: String, dosageMg: String, capacityText: String, budget: String, rate: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copayText = copayText
            self.segment = segment
            self.dosageMg = dosageMg
            self.capacityText = capacityText
            self.budget = budget
            self.rate = rate
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCensusCheckpointView(_ item: PrimaryCensusCheckpoint) -> PrimaryCensusCheckpointView {
        return PrimaryCensusCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            copayText: String(format: "%.2f", item.copay),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            capacityText: String(item.capacity),
            budget: String(format: "%.2f", item.budget),
            rate: String(format: "%.2f", item.rate),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCensusCheckpointViews(_ items: [PrimaryCensusCheckpoint]) -> [PrimaryCensusCheckpointView] {
        var views: [PrimaryCensusCheckpointView] = []
        for item in items {
            views.append(toPrimaryCensusCheckpointView(item))
        }
        return views
    }

    static func sumPrimaryCensusCheckpointView(_ view: PrimaryCensusCheckpointView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCopay + parsedDosageMg + Double(parsedCapacity)
    }
}
