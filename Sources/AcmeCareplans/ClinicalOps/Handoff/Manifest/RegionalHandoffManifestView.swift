import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional handoff manifest.
    final class RegionalHandoffManifestView {
        var codeText: String
        var labelText: String
        var batchSize: String
        var facility: String
        var bed: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, labelText: String, batchSize: String, facility: String, bed: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.batchSize = batchSize
            self.facility = facility
            self.bed = bed
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalHandoffManifestView(_ item: RegionalHandoffManifest) -> RegionalHandoffManifestView {
        return RegionalHandoffManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            batchSize: String(item.batchSize),
            facility: item.facility,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalHandoffManifestViews(_ items: [RegionalHandoffManifest]) -> [RegionalHandoffManifestView] {
        var views: [RegionalHandoffManifestView] = []
        for item in items {
            views.append(toRegionalHandoffManifestView(item))
        }
        return views
    }

    static func sumRegionalHandoffManifestView(_ view: RegionalHandoffManifestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays)
    }
}
