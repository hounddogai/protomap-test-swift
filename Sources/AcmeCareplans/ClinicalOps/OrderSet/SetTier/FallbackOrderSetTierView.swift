import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback order set tier.
    final class FallbackOrderSetTierView {
        var code: String
        var label: String
        var bedText: String
        var startsAt: String
        var ratioText: String
        var visitMinutes: String
        var countryText: String
        var encounterID: String
        var visibleText: String
        var reviewer: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, label: String, bedText: String, startsAt: String, ratioText: String, visitMinutes: String, countryText: String, encounterID: String, visibleText: String, reviewer: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bedText = bedText
            self.startsAt = startsAt
            self.ratioText = ratioText
            self.visitMinutes = visitMinutes
            self.countryText = countryText
            self.encounterID = encounterID
            self.visibleText = visibleText
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackOrderSetTierView(_ item: FallbackOrderSetTier) -> FallbackOrderSetTierView {
        return FallbackOrderSetTierView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            bedText: item.bed,
            startsAt: String(item.startsAt),
            ratioText: String(format: "%.2f", item.ratio),
            visitMinutes: String(item.visitMinutes),
            countryText: item.country,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            visibleText: "\(item.visible)",
            reviewer: item.reviewer,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackOrderSetTierViews(_ items: [FallbackOrderSetTier]) -> [FallbackOrderSetTierView] {
        var views: [FallbackOrderSetTierView] = []
        for item in items {
            views.append(toFallbackOrderSetTierView(item))
        }
        return views
    }

    static func sumFallbackOrderSetTierView(_ view: FallbackOrderSetTierView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedStartsAt) + parsedRatio + Double(parsedVisitMinutes)
    }
}
