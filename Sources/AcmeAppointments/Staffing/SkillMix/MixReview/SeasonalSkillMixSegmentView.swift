import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal skill mix segment.
    final class SeasonalSkillMixSegmentView {
        var code: String
        var name: String
        var categoryText: String
        var allergyText: String
        var ratioText: String
        var checksum: String
        var durationMinutes: String
        var maximum: String
        var statusLabel: String

        init(code: String, name: String, categoryText: String, allergyText: String, ratioText: String, checksum: String, durationMinutes: String, maximum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.categoryText = categoryText
            self.allergyText = allergyText
            self.ratioText = ratioText
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSkillMixSegmentView(_ item: SeasonalSkillMixSegment) -> SeasonalSkillMixSegmentView {
        return SeasonalSkillMixSegmentView(
            code: item.code,
            name: item.name,
            categoryText: item.category,
            allergyText: item.allergy,
            ratioText: String(format: "%.2f", item.ratio),
            checksum: item.checksum,
            durationMinutes: String(item.durationMinutes),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSkillMixSegmentViews(_ items: [SeasonalSkillMixSegment]) -> [SeasonalSkillMixSegmentView] {
        var views: [SeasonalSkillMixSegmentView] = []
        for item in items {
            views.append(toSeasonalSkillMixSegmentView(item))
        }
        return views
    }

    static func sumSeasonalSkillMixSegmentView(_ view: SeasonalSkillMixSegmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRatio + Double(parsedDurationMinutes) + parsedMaximum
    }
}
