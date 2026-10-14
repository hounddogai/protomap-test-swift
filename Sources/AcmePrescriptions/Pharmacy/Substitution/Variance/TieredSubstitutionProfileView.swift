import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered substitution profile.
    final class TieredSubstitutionProfileView {
        var code: String
        var label: String
        var score: String
        var startsAtText: String
        var createdAt: String
        var visible: String
        var summary: String
        var sourceText: String
        var statusLabel: String

        init(code: String, label: String, score: String, startsAtText: String, createdAt: String, visible: String, summary: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.startsAtText = startsAtText
            self.createdAt = createdAt
            self.visible = visible
            self.summary = summary
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSubstitutionProfileView(_ item: TieredSubstitutionProfile) -> TieredSubstitutionProfileView {
        return TieredSubstitutionProfileView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            score: String(format: "%.2f", item.score),
            startsAtText: String(item.startsAt),
            createdAt: String(item.createdAt),
            visible: "\(item.visible)",
            summary: Kit.Text.truncate(item.summary, limit: 40),
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSubstitutionProfileViews(_ items: [TieredSubstitutionProfile]) -> [TieredSubstitutionProfileView] {
        var views: [TieredSubstitutionProfileView] = []
        for item in items {
            views.append(toTieredSubstitutionProfileView(item))
        }
        return views
    }

    static func sumTieredSubstitutionProfileView(_ view: TieredSubstitutionProfileView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedScore + Double(parsedStartsAt) + Double(parsedCreatedAt)
    }
}
