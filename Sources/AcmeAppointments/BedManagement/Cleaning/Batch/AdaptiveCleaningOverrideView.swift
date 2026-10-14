import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive cleaning override.
    final class AdaptiveCleaningOverrideView {
        var codeText: String
        var title: String
        var locale: String
        var ownerID: String
        var score: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, title: String, locale: String, ownerID: String, score: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.locale = locale
            self.ownerID = ownerID
            self.score = score
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCleaningOverrideView(_ item: AdaptiveCleaningOverride) -> AdaptiveCleaningOverrideView {
        return AdaptiveCleaningOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            locale: item.locale,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            score: String(format: "%.2f", item.score),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCleaningOverrideViews(_ items: [AdaptiveCleaningOverride]) -> [AdaptiveCleaningOverrideView] {
        var views: [AdaptiveCleaningOverrideView] = []
        for item in items {
            views.append(toAdaptiveCleaningOverrideView(item))
        }
        return views
    }

    static func sumAdaptiveCleaningOverrideView(_ view: AdaptiveCleaningOverrideView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
