import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped isolation schedule.
    final class CappedIsolationScheduleView {
        var code: String
        var name: String
        var graceDaysText: String
        var locale: String
        var allergy: String
        var archived: String
        var channelText: String
        var weight: String
        var phone: String
        var ceiling: String
        var facilityText: String
        var statusLabel: String

        init(code: String, name: String, graceDaysText: String, locale: String, allergy: String, archived: String, channelText: String, weight: String, phone: String, ceiling: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDaysText = graceDaysText
            self.locale = locale
            self.allergy = allergy
            self.archived = archived
            self.channelText = channelText
            self.weight = weight
            self.phone = phone
            self.ceiling = ceiling
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedIsolationScheduleView(_ item: CappedIsolationSchedule) -> CappedIsolationScheduleView {
        return CappedIsolationScheduleView(
            code: item.code,
            name: item.name,
            graceDaysText: String(item.graceDays),
            locale: item.locale,
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            archived: "\(item.archived)",
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            weight: String(format: "%.2f", item.weight),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            facilityText: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedIsolationScheduleViews(_ items: [CappedIsolationSchedule]) -> [CappedIsolationScheduleView] {
        var views: [CappedIsolationScheduleView] = []
        for item in items {
            views.append(toCappedIsolationScheduleView(item))
        }
        return views
    }

    static func sumCappedIsolationScheduleView(_ view: CappedIsolationScheduleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedGraceDays) + parsedWeight + parsedCeiling
    }
}
