import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched witness bundle.
    final class BatchedWitnessBundleView {
        var code: String
        var name: String
        var batchSize: String
        var contactEmail: String
        var notesText: String
        var specialty: String
        var statusLabel: String

        init(code: String, name: String, batchSize: String, contactEmail: String, notesText: String, specialty: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.notesText = notesText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedWitnessBundleView(_ item: BatchedWitnessBundle) -> BatchedWitnessBundleView {
        return BatchedWitnessBundleView(
            code: item.code,
            name: item.name,
            batchSize: String(item.batchSize),
            contactEmail: item.contactEmail,
            notesText: item.notes,
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedWitnessBundleViews(_ items: [BatchedWitnessBundle]) -> [BatchedWitnessBundleView] {
        var views: [BatchedWitnessBundleView] = []
        for item in items {
            views.append(toBatchedWitnessBundleView(item))
        }
        return views
    }

    static func sumBatchedWitnessBundleView(_ view: BatchedWitnessBundleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
