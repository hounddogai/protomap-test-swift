import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal care gap entry.
    final class SeasonalCareGapEntryView {
        var code: String
        var titleText: String
        var currency: String
        var allergy: String
        var ward: String
        var copayText: String
        var version: String
        var ceiling: String
        var statusLabel: String

        init(code: String, titleText: String, currency: String, allergy: String, ward: String, copayText: String, version: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.currency = currency
            self.allergy = allergy
            self.ward = ward
            self.copayText = copayText
            self.version = version
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareGapEntryView(_ item: SeasonalCareGapEntry) -> SeasonalCareGapEntryView {
        return SeasonalCareGapEntryView(
            code: item.code,
            titleText: item.title,
            currency: Kit.Text.truncate(item.currency, limit: 80),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            copayText: String(format: "%.2f", item.copay),
            version: String(item.version),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareGapEntryViews(_ items: [SeasonalCareGapEntry]) -> [SeasonalCareGapEntryView] {
        var views: [SeasonalCareGapEntryView] = []
        for item in items {
            views.append(toSeasonalCareGapEntryView(item))
        }
        return views
    }

    static func sumSeasonalCareGapEntryView(_ view: SeasonalCareGapEntryView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCopay + Double(parsedVersion) + parsedCeiling
    }
}
