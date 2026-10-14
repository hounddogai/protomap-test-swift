import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered outreach score.
    final class TieredOutreachScoreView {
        var code: String
        var name: String
        var versionText: String
        var label: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, versionText: String, label: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.versionText = versionText
            self.label = label
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOutreachScoreView(_ item: TieredOutreachScore) -> TieredOutreachScoreView {
        return TieredOutreachScoreView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            versionText: String(item.version),
            label: item.label,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOutreachScoreViews(_ items: [TieredOutreachScore]) -> [TieredOutreachScoreView] {
        var views: [TieredOutreachScoreView] = []
        for item in items {
            views.append(toTieredOutreachScoreView(item))
        }
        return views
    }

    static func sumTieredOutreachScoreView(_ view: TieredOutreachScoreView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedVersion) + Double(parsedCreatedAt)
    }
}
