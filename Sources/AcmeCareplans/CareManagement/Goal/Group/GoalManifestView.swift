import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal manifest.
    final class GoalManifestView {
        var code: String
        var label: String
        var region: String
        var phone: String
        var country: String
        var archived: String
        var expiresAtText: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, region: String, phone: String, country: String, archived: String, expiresAtText: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.region = region
            self.phone = phone
            self.country = country
            self.archived = archived
            self.expiresAtText = expiresAtText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toGoalManifestView(_ item: GoalManifest) -> GoalManifestView {
        return GoalManifestView(
            code: item.code,
            label: item.label,
            region: item.region,
            phone: Kit.Text.truncate(item.phone, limit: 120),
            country: item.country,
            archived: "\(item.archived)",
            expiresAtText: String(item.expiresAt),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalManifestViews(_ items: [GoalManifest]) -> [GoalManifestView] {
        var views: [GoalManifestView] = []
        for item in items {
            views.append(toGoalManifestView(item))
        }
        return views
    }

    static func sumGoalManifestView(_ view: GoalManifestView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedVisitMinutes)
    }
}
