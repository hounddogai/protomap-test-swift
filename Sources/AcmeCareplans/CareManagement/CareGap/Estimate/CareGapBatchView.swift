import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap batch.
    final class CareGapBatchView {
        var code: String
        var nameText: String
        var threshold: String
        var regionText: String
        var revision: String
        var statusLabel: String

        init(code: String, nameText: String, threshold: String, regionText: String, revision: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.threshold = threshold
            self.regionText = regionText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapBatchView(_ item: CareGapBatch) -> CareGapBatchView {
        return CareGapBatchView(
            code: item.code,
            nameText: item.name,
            threshold: String(format: "%.2f", item.threshold),
            regionText: item.region,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapBatchViews(_ items: [CareGapBatch]) -> [CareGapBatchView] {
        var views: [CareGapBatchView] = []
        for item in items {
            views.append(toCareGapBatchView(item))
        }
        return views
    }

    static func sumCareGapBatchView(_ view: CareGapBatchView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedThreshold + Double(parsedRevision)
    }
}
