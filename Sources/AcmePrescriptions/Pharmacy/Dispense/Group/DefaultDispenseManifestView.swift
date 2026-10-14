import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default dispense manifest.
    final class DefaultDispenseManifestView {
        var code: String
        var title: String
        var timezoneText: String
        var ownerID: String
        var patientRef: String
        var retries: String
        var limit: String
        var ceiling: String
        var ratioText: String
        var notesText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, timezoneText: String, ownerID: String, patientRef: String, retries: String, limit: String, ceiling: String, ratioText: String, notesText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.timezoneText = timezoneText
            self.ownerID = ownerID
            self.patientRef = patientRef
            self.retries = retries
            self.limit = limit
            self.ceiling = ceiling
            self.ratioText = ratioText
            self.notesText = notesText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDispenseManifestView(_ item: DefaultDispenseManifest) -> DefaultDispenseManifestView {
        return DefaultDispenseManifestView(
            code: item.code,
            title: item.title,
            timezoneText: item.timezone,
            ownerID: item.ownerID,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            retries: String(item.retries),
            limit: String(item.limit),
            ceiling: String(format: "%.2f", item.ceiling),
            ratioText: String(format: "%.2f", item.ratio),
            notesText: item.notes,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDispenseManifestViews(_ items: [DefaultDispenseManifest]) -> [DefaultDispenseManifestView] {
        var views: [DefaultDispenseManifestView] = []
        for item in items {
            views.append(toDefaultDispenseManifestView(item))
        }
        return views
    }

    static func sumDefaultDispenseManifestView(_ view: DefaultDispenseManifestView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRetries) + Double(parsedLimit) + parsedCeiling
    }
}
