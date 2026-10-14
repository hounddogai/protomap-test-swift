import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning manifest.
    final class CleaningManifestView {
        var codeText: String
        var labelText: String
        var contactEmail: String
        var windowDaysText: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, labelText: String, contactEmail: String, windowDaysText: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.contactEmail = contactEmail
            self.windowDaysText = windowDaysText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningManifestView(_ item: CleaningManifest) -> CleaningManifestView {
        return CleaningManifestView(
            codeText: item.code,
            labelText: item.label,
            contactEmail: item.contactEmail,
            windowDaysText: String(item.windowDays),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningManifestViews(_ items: [CleaningManifest]) -> [CleaningManifestView] {
        var views: [CleaningManifestView] = []
        for item in items {
            views.append(toCleaningManifestView(item))
        }
        return views
    }

    static func sumCleaningManifestView(_ view: CleaningManifestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
