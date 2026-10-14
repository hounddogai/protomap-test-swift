import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback accession batch.
    final class FallbackAccessionBatchView {
        var code: String
        var title: String
        var sequenceText: String
        var maximumText: String
        var versionText: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, sequenceText: String, maximumText: String, versionText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequenceText = sequenceText
            self.maximumText = maximumText
            self.versionText = versionText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAccessionBatchView(_ item: FallbackAccessionBatch) -> FallbackAccessionBatchView {
        return FallbackAccessionBatchView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            sequenceText: String(item.sequence),
            maximumText: String(format: "%.2f", item.maximum),
            versionText: String(item.version),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAccessionBatchViews(_ items: [FallbackAccessionBatch]) -> [FallbackAccessionBatchView] {
        var views: [FallbackAccessionBatchView] = []
        for item in items {
            views.append(toFallbackAccessionBatchView(item))
        }
        return views
    }

    static func sumFallbackAccessionBatchView(_ view: FallbackAccessionBatchView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedSequence) + parsedMaximum + Double(parsedVersion)
    }
}
