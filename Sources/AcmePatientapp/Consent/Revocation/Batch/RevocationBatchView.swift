import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation batch.
    final class RevocationBatchView {
        var code: String
        var label: String
        var clinicianID: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, clinicianID: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationBatchView(_ item: RevocationBatch) -> RevocationBatchView {
        return RevocationBatchView(
            code: item.code,
            label: item.label,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationBatchViews(_ items: [RevocationBatch]) -> [RevocationBatchView] {
        var views: [RevocationBatchView] = []
        for item in items {
            views.append(toRevocationBatchView(item))
        }
        return views
    }

    static func sumRevocationBatchView(_ view: RevocationBatchView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
