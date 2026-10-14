import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary cleaning manifest.
    final class PrimaryCleaningManifestView {
        var codeText: String
        var title: String
        var sequence: String
        var encounterID: String
        var phone: String
        var ownerID: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, title: String, sequence: String, encounterID: String, phone: String, ownerID: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.sequence = sequence
            self.encounterID = encounterID
            self.phone = phone
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCleaningManifestView(_ item: PrimaryCleaningManifest) -> PrimaryCleaningManifestView {
        return PrimaryCleaningManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            sequence: String(item.sequence),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            phone: item.phone,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCleaningManifestViews(_ items: [PrimaryCleaningManifest]) -> [PrimaryCleaningManifestView] {
        var views: [PrimaryCleaningManifestView] = []
        for item in items {
            views.append(toPrimaryCleaningManifestView(item))
        }
        return views
    }

    static func sumPrimaryCleaningManifestView(_ view: PrimaryCleaningManifestView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedSequence) + Double(parsedWindowDays)
    }
}
