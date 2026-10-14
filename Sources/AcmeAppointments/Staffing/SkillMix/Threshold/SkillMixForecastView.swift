import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix forecast.
    final class SkillMixForecastView {
        var codeText: String
        var titleText: String
        var timezoneText: String
        var ward: String
        var refills: String
        var limitText: String
        var externalRef: String
        var localeText: String
        var checksum: String
        var ceiling: String
        var visible: String
        var statusLabel: String

        init(codeText: String, titleText: String, timezoneText: String, ward: String, refills: String, limitText: String, externalRef: String, localeText: String, checksum: String, ceiling: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.timezoneText = timezoneText
            self.ward = ward
            self.refills = refills
            self.limitText = limitText
            self.externalRef = externalRef
            self.localeText = localeText
            self.checksum = checksum
            self.ceiling = ceiling
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixForecastView(_ item: SkillMixForecast) -> SkillMixForecastView {
        return SkillMixForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            timezoneText: item.timezone,
            ward: item.ward,
            refills: String(item.refills),
            limitText: String(item.limit),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            localeText: item.locale,
            checksum: item.checksum,
            ceiling: String(format: "%.2f", item.ceiling),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixForecastViews(_ items: [SkillMixForecast]) -> [SkillMixForecastView] {
        var views: [SkillMixForecastView] = []
        for item in items {
            views.append(toSkillMixForecastView(item))
        }
        return views
    }

    static func sumSkillMixForecastView(_ view: SkillMixForecastView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRefills) + Double(parsedLimit) + parsedCeiling
    }
}
