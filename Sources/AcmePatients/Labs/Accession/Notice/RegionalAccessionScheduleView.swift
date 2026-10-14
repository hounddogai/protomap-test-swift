import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional accession schedule.
    final class RegionalAccessionScheduleView {
        var code: String
        var title: String
        var active: String
        var pinned: String
        var graceDays: String
        var rate: String
        var dosageMg: String
        var floorValueText: String
        var channel: String
        var copay: String
        var allergy: String
        var statusLabel: String

        init(code: String, title: String, active: String, pinned: String, graceDays: String, rate: String, dosageMg: String, floorValueText: String, channel: String, copay: String, allergy: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.active = active
            self.pinned = pinned
            self.graceDays = graceDays
            self.rate = rate
            self.dosageMg = dosageMg
            self.floorValueText = floorValueText
            self.channel = channel
            self.copay = copay
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAccessionScheduleView(_ item: RegionalAccessionSchedule) -> RegionalAccessionScheduleView {
        return RegionalAccessionScheduleView(
            code: item.code,
            title: item.title,
            active: "\(item.active)",
            pinned: "\(item.pinned)",
            graceDays: String(item.graceDays),
            rate: String(format: "%.2f", item.rate),
            dosageMg: String(format: "%.2f", item.dosageMg),
            floorValueText: String(format: "%.2f", item.floorValue),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            copay: String(format: "%.2f", item.copay),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAccessionScheduleViews(_ items: [RegionalAccessionSchedule]) -> [RegionalAccessionScheduleView] {
        var views: [RegionalAccessionScheduleView] = []
        for item in items {
            views.append(toRegionalAccessionScheduleView(item))
        }
        return views
    }

    static func sumRegionalAccessionScheduleView(_ view: RegionalAccessionScheduleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedGraceDays) + parsedRate + parsedDosageMg
    }
}
