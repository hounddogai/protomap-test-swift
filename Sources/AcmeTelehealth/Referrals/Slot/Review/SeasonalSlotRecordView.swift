import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal slot record.
    final class SeasonalSlotRecordView {
        var code: String
        var nameText: String
        var rate: String
        var updatedAt: String
        var ward: String
        var locale: String
        var ceiling: String
        var statusLabel: String

        init(code: String, nameText: String, rate: String, updatedAt: String, ward: String, locale: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.rate = rate
            self.updatedAt = updatedAt
            self.ward = ward
            self.locale = locale
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSlotRecordView(_ item: SeasonalSlotRecord) -> SeasonalSlotRecordView {
        return SeasonalSlotRecordView(
            code: item.code,
            nameText: item.name,
            rate: String(format: "%.2f", item.rate),
            updatedAt: String(item.updatedAt),
            ward: item.ward,
            locale: Kit.Text.truncate(item.locale, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSlotRecordViews(_ items: [SeasonalSlotRecord]) -> [SeasonalSlotRecordView] {
        var views: [SeasonalSlotRecordView] = []
        for item in items {
            views.append(toSeasonalSlotRecordView(item))
        }
        return views
    }

    static func sumSeasonalSlotRecordView(_ view: SeasonalSlotRecordView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedRate + Double(parsedUpdatedAt) + parsedCeiling
    }
}
