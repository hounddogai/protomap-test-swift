import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default cleaning manifest.
    final class DefaultCleaningManifestView {
        var code: String
        var label: String
        var batchSizeText: String
        var graceDays: String
        var notes: String
        var windowDaysText: String
        var updatedAt: String
        var expiresAt: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, batchSizeText: String, graceDays: String, notes: String, windowDaysText: String, updatedAt: String, expiresAt: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSizeText = batchSizeText
            self.graceDays = graceDays
            self.notes = notes
            self.windowDaysText = windowDaysText
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCleaningManifestView(_ item: DefaultCleaningManifest) -> DefaultCleaningManifestView {
        return DefaultCleaningManifestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            batchSizeText: String(item.batchSize),
            graceDays: String(item.graceDays),
            notes: item.notes,
            windowDaysText: String(item.windowDays),
            updatedAt: String(item.updatedAt),
            expiresAt: String(item.expiresAt),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCleaningManifestViews(_ items: [DefaultCleaningManifest]) -> [DefaultCleaningManifestView] {
        var views: [DefaultCleaningManifestView] = []
        for item in items {
            views.append(toDefaultCleaningManifestView(item))
        }
        return views
    }

    static func sumDefaultCleaningManifestView(_ view: DefaultCleaningManifestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays) + Double(parsedWindowDays)
    }
}
