import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure checkpoint.
    final class DisclosureCheckpointView {
        var code: String
        var title: String
        var active: String
        var categoryText: String
        var expiresAt: String
        var nameText: String
        var ownerID: String
        var weight: String
        var patientRefText: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, title: String, active: String, categoryText: String, expiresAt: String, nameText: String, ownerID: String, weight: String, patientRefText: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.active = active
            self.categoryText = categoryText
            self.expiresAt = expiresAt
            self.nameText = nameText
            self.ownerID = ownerID
            self.weight = weight
            self.patientRefText = patientRefText
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureCheckpointView(_ item: DisclosureCheckpoint) -> DisclosureCheckpointView {
        return DisclosureCheckpointView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            active: "\(item.active)",
            categoryText: item.category,
            expiresAt: String(item.expiresAt),
            nameText: item.name,
            ownerID: item.ownerID,
            weight: String(format: "%.2f", item.weight),
            patientRefText: item.patientRef,
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureCheckpointViews(_ items: [DisclosureCheckpoint]) -> [DisclosureCheckpointView] {
        var views: [DisclosureCheckpointView] = []
        for item in items {
            views.append(toDisclosureCheckpointView(item))
        }
        return views
    }

    static func sumDisclosureCheckpointView(_ view: DisclosureCheckpointView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedExpiresAt) + parsedWeight
    }
}
