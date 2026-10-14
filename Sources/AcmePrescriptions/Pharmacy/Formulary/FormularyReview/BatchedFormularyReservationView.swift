import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched formulary reservation.
    final class BatchedFormularyReservationView {
        var code: String
        var name: String
        var weight: String
        var attempts: String
        var checksum: String
        var segment: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, weight: String, attempts: String, checksum: String, segment: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.attempts = attempts
            self.checksum = checksum
            self.segment = segment
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedFormularyReservationView(_ item: BatchedFormularyReservation) -> BatchedFormularyReservationView {
        return BatchedFormularyReservationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            attempts: String(item.attempts),
            checksum: item.checksum,
            segment: item.segment,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedFormularyReservationViews(_ items: [BatchedFormularyReservation]) -> [BatchedFormularyReservationView] {
        var views: [BatchedFormularyReservationView] = []
        for item in items {
            views.append(toBatchedFormularyReservationView(item))
        }
        return views
    }

    static func sumBatchedFormularyReservationView(_ view: BatchedFormularyReservationView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedWeight + Double(parsedAttempts) + Double(parsedBatchSize)
    }
}
