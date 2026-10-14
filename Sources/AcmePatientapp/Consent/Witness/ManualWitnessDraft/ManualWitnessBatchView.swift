import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual witness batch.
    final class ManualWitnessBatchView {
        var code: String
        var nameText: String
        var reviewerText: String
        var batchSizeText: String
        var startsAt: String
        var segment: String
        var patientRefText: String
        var notes: String
        var statusLabel: String

        init(code: String, nameText: String, reviewerText: String, batchSizeText: String, startsAt: String, segment: String, patientRefText: String, notes: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.reviewerText = reviewerText
            self.batchSizeText = batchSizeText
            self.startsAt = startsAt
            self.segment = segment
            self.patientRefText = patientRefText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toManualWitnessBatchView(_ item: ManualWitnessBatch) -> ManualWitnessBatchView {
        return ManualWitnessBatchView(
            code: item.code,
            nameText: item.name,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 64),
            batchSizeText: String(item.batchSize),
            startsAt: String(item.startsAt),
            segment: item.segment,
            patientRefText: item.patientRef,
            notes: Kit.Text.truncate(item.notes, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualWitnessBatchViews(_ items: [ManualWitnessBatch]) -> [ManualWitnessBatchView] {
        var views: [ManualWitnessBatchView] = []
        for item in items {
            views.append(toManualWitnessBatchView(item))
        }
        return views
    }

    static func sumManualWitnessBatchView(_ view: ManualWitnessBatchView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedStartsAt)
    }
}
