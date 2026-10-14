import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result manifest.
    final class ResultManifestView {
        var codeText: String
        var label: String
        var externalRef: String
        var ratio: String
        var priority: String
        var wardText: String
        var batchSize: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, label: String, externalRef: String, ratio: String, priority: String, wardText: String, batchSize: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.externalRef = externalRef
            self.ratio = ratio
            self.priority = priority
            self.wardText = wardText
            self.batchSize = batchSize
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toResultManifestView(_ item: ResultManifest) -> ResultManifestView {
        return ResultManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            priority: String(item.priority),
            wardText: Kit.Text.truncate(item.ward, limit: 120),
            batchSize: String(item.batchSize),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultManifestViews(_ items: [ResultManifest]) -> [ResultManifestView] {
        var views: [ResultManifestView] = []
        for item in items {
            views.append(toResultManifestView(item))
        }
        return views
    }

    static func sumResultManifestView(_ view: ResultManifestView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedRatio + Double(parsedPriority) + Double(parsedBatchSize)
    }
}
