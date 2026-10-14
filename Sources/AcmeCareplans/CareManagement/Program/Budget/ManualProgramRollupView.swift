import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual program rollup.
    final class ManualProgramRollupView {
        var codeText: String
        var nameText: String
        var country: String
        var regionText: String
        var sourceText: String
        var approved: String
        var score: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, nameText: String, country: String, regionText: String, sourceText: String, approved: String, score: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.country = country
            self.regionText = regionText
            self.sourceText = sourceText
            self.approved = approved
            self.score = score
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toManualProgramRollupView(_ item: ManualProgramRollup) -> ManualProgramRollupView {
        return ManualProgramRollupView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            country: Kit.Text.truncate(item.country, limit: 40),
            regionText: Kit.Text.truncate(item.region, limit: 64),
            sourceText: item.source,
            approved: "\(item.approved)",
            score: String(format: "%.2f", item.score),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualProgramRollupViews(_ items: [ManualProgramRollup]) -> [ManualProgramRollupView] {
        var views: [ManualProgramRollupView] = []
        for item in items {
            views.append(toManualProgramRollupView(item))
        }
        return views
    }

    static func sumManualProgramRollupView(_ view: ManualProgramRollupView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
