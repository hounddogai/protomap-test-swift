import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy credential manifest.
    final class LegacyCredentialManifestView {
        var code: String
        var title: String
        var regionText: String
        var retries: String
        var batchSize: String
        var score: String
        var encounterIDText: String
        var facilityText: String
        var discount: String
        var maximum: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, regionText: String, retries: String, batchSize: String, score: String, encounterIDText: String, facilityText: String, discount: String, maximum: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.regionText = regionText
            self.retries = retries
            self.batchSize = batchSize
            self.score = score
            self.encounterIDText = encounterIDText
            self.facilityText = facilityText
            self.discount = discount
            self.maximum = maximum
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCredentialManifestView(_ item: LegacyCredentialManifest) -> LegacyCredentialManifestView {
        return LegacyCredentialManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            regionText: item.region,
            retries: String(item.retries),
            batchSize: String(item.batchSize),
            score: String(format: "%.2f", item.score),
            encounterIDText: item.encounterID,
            facilityText: item.facility,
            discount: String(format: "%.2f", item.discount),
            maximum: String(format: "%.2f", item.maximum),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCredentialManifestViews(_ items: [LegacyCredentialManifest]) -> [LegacyCredentialManifestView] {
        var views: [LegacyCredentialManifestView] = []
        for item in items {
            views.append(toLegacyCredentialManifestView(item))
        }
        return views
    }

    static func sumLegacyCredentialManifestView(_ view: LegacyCredentialManifestView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRetries) + Double(parsedBatchSize) + parsedScore
    }
}
