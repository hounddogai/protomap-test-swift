import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy inventory manifest.
    final class LegacyInventoryManifestView {
        var codeText: String
        var label: String
        var reviewerText: String
        var diagnosisCode: String
        var rate: String
        var timezoneText: String
        var source: String
        var statusLabel: String

        init(codeText: String, label: String, reviewerText: String, diagnosisCode: String, rate: String, timezoneText: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.reviewerText = reviewerText
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.timezoneText = timezoneText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInventoryManifestView(_ item: LegacyInventoryManifest) -> LegacyInventoryManifestView {
        return LegacyInventoryManifestView(
            codeText: item.code,
            label: item.label,
            reviewerText: item.reviewer,
            diagnosisCode: item.diagnosisCode,
            rate: String(format: "%.2f", item.rate),
            timezoneText: item.timezone,
            source: Kit.Text.truncate(item.source, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInventoryManifestViews(_ items: [LegacyInventoryManifest]) -> [LegacyInventoryManifestView] {
        var views: [LegacyInventoryManifestView] = []
        for item in items {
            views.append(toLegacyInventoryManifestView(item))
        }
        return views
    }

    static func sumLegacyInventoryManifestView(_ view: LegacyInventoryManifestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
