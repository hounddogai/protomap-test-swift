import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback accession threshold.
    final class FallbackAccessionThresholdView {
        var code: String
        var name: String
        var endsAt: String
        var label: String
        var margin: String
        var externalRef: String
        var approved: String
        var batchSize: String
        var segmentText: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, label: String, margin: String, externalRef: String, approved: String, batchSize: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.label = label
            self.margin = margin
            self.externalRef = externalRef
            self.approved = approved
            self.batchSize = batchSize
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAccessionThresholdView(_ item: FallbackAccessionThreshold) -> FallbackAccessionThresholdView {
        return FallbackAccessionThresholdView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            endsAt: String(item.endsAt),
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            approved: "\(item.approved)",
            batchSize: String(item.batchSize),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAccessionThresholdViews(_ items: [FallbackAccessionThreshold]) -> [FallbackAccessionThresholdView] {
        var views: [FallbackAccessionThresholdView] = []
        for item in items {
            views.append(toFallbackAccessionThresholdView(item))
        }
        return views
    }

    static func sumFallbackAccessionThresholdView(_ view: FallbackAccessionThresholdView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedEndsAt) + parsedMargin + Double(parsedBatchSize)
    }
}
