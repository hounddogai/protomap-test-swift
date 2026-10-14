import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual inventory manifest.
    final class ManualInventoryManifestView {
        var codeText: String
        var label: String
        var startsAt: String
        var bed: String
        var minimum: String
        var retries: String
        var statusLabel: String

        init(codeText: String, label: String, startsAt: String, bed: String, minimum: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.startsAt = startsAt
            self.bed = bed
            self.minimum = minimum
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toManualInventoryManifestView(_ item: ManualInventoryManifest) -> ManualInventoryManifestView {
        return ManualInventoryManifestView(
            codeText: item.code,
            label: item.label,
            startsAt: String(item.startsAt),
            bed: item.bed,
            minimum: String(format: "%.2f", item.minimum),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualInventoryManifestViews(_ items: [ManualInventoryManifest]) -> [ManualInventoryManifestView] {
        var views: [ManualInventoryManifestView] = []
        for item in items {
            views.append(toManualInventoryManifestView(item))
        }
        return views
    }

    static func sumManualInventoryManifestView(_ view: ManualInventoryManifestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedStartsAt) + parsedMinimum + Double(parsedRetries)
    }
}
