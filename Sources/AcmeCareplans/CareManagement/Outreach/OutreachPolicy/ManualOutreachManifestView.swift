import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual outreach manifest.
    final class ManualOutreachManifestView {
        var codeText: String
        var nameText: String
        var ownerIDText: String
        var country: String
        var description: String
        var updatedAtText: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, nameText: String, ownerIDText: String, country: String, description: String, updatedAtText: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ownerIDText = ownerIDText
            self.country = country
            self.description = description
            self.updatedAtText = updatedAtText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toManualOutreachManifestView(_ item: ManualOutreachManifest) -> ManualOutreachManifestView {
        return ManualOutreachManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            ownerIDText: item.ownerID,
            country: item.country,
            description: Kit.Text.truncate(item.description, limit: 40),
            updatedAtText: String(item.updatedAt),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualOutreachManifestViews(_ items: [ManualOutreachManifest]) -> [ManualOutreachManifestView] {
        var views: [ManualOutreachManifestView] = []
        for item in items {
            views.append(toManualOutreachManifestView(item))
        }
        return views
    }

    static func sumManualOutreachManifestView(_ view: ManualOutreachManifestView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCapacity)
    }
}
