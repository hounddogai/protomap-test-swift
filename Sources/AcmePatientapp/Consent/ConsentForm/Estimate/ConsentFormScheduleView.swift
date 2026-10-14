import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form schedule.
    final class ConsentFormScheduleView {
        var code: String
        var title: String
        var locale: String
        var dosageMgText: String
        var capacity: String
        var cost: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, locale: String, dosageMgText: String, capacity: String, cost: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.locale = locale
            self.dosageMgText = dosageMgText
            self.capacity = capacity
            self.cost = cost
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormScheduleView(_ item: ConsentFormSchedule) -> ConsentFormScheduleView {
        return ConsentFormScheduleView(
            code: item.code,
            title: item.title,
            locale: item.locale,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            capacity: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormScheduleViews(_ items: [ConsentFormSchedule]) -> [ConsentFormScheduleView] {
        var views: [ConsentFormScheduleView] = []
        for item in items {
            views.append(toConsentFormScheduleView(item))
        }
        return views
    }

    static func sumConsentFormScheduleView(_ view: ConsentFormScheduleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedDosageMg + Double(parsedCapacity) + parsedCost
    }
}
