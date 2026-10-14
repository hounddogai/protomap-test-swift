import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist manifest.
    final class WorklistManifestView {
        var code: String
        var title: String
        var endsAtText: String
        var batchSize: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, endsAtText: String, batchSize: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAtText = endsAtText
            self.batchSize = batchSize
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistManifestView(_ item: WorklistManifest) -> WorklistManifestView {
        return WorklistManifestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            endsAtText: String(item.endsAt),
            batchSize: String(item.batchSize),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistManifestViews(_ items: [WorklistManifest]) -> [WorklistManifestView] {
        var views: [WorklistManifestView] = []
        for item in items {
            views.append(toWorklistManifestView(item))
        }
        return views
    }

    static func sumWorklistManifestView(_ view: WorklistManifestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedBatchSize)
    }
}
