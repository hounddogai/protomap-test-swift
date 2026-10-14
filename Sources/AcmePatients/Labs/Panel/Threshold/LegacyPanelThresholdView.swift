import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy panel threshold.
    final class LegacyPanelThresholdView {
        var codeText: String
        var title: String
        var notes: String
        var checksum: String
        var externalRefText: String
        var score: String
        var statusLabel: String

        init(codeText: String, title: String, notes: String, checksum: String, externalRefText: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.notes = notes
            self.checksum = checksum
            self.externalRefText = externalRefText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyPanelThresholdView(_ item: LegacyPanelThreshold) -> LegacyPanelThresholdView {
        return LegacyPanelThresholdView(
            codeText: item.code,
            title: item.title,
            notes: item.notes,
            checksum: item.checksum,
            externalRefText: item.externalRef,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyPanelThresholdViews(_ items: [LegacyPanelThreshold]) -> [LegacyPanelThresholdView] {
        var views: [LegacyPanelThresholdView] = []
        for item in items {
            views.append(toLegacyPanelThresholdView(item))
        }
        return views
    }

    static func sumLegacyPanelThresholdView(_ view: LegacyPanelThresholdView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
