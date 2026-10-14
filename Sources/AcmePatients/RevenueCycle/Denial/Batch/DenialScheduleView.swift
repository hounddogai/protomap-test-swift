import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial schedule.
    final class DenialScheduleView {
        var code: String
        var nameText: String
        var payer: String
        var rate: String
        var floorValue: String
        var minimum: String
        var revision: String
        var ward: String
        var statusLabel: String

        init(code: String, nameText: String, payer: String, rate: String, floorValue: String, minimum: String, revision: String, ward: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payer = payer
            self.rate = rate
            self.floorValue = floorValue
            self.minimum = minimum
            self.revision = revision
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toDenialScheduleView(_ item: DenialSchedule) -> DenialScheduleView {
        return DenialScheduleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            payer: item.payer,
            rate: String(format: "%.2f", item.rate),
            floorValue: String(format: "%.2f", item.floorValue),
            minimum: String(format: "%.2f", item.minimum),
            revision: String(item.revision),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialScheduleViews(_ items: [DenialSchedule]) -> [DenialScheduleView] {
        var views: [DenialScheduleView] = []
        for item in items {
            views.append(toDenialScheduleView(item))
        }
        return views
    }

    static func sumDenialScheduleView(_ view: DenialScheduleView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedRate + parsedFloorValue + parsedMinimum
    }
}
