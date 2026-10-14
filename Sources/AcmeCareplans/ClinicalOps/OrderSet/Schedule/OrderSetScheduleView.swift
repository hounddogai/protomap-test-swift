import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set schedule.
    final class OrderSetScheduleView {
        var code: String
        var titleText: String
        var weight: String
        var visibleText: String
        var durationMinutesText: String
        var dosageMgText: String
        var copayText: String
        var statusLabel: String

        init(code: String, titleText: String, weight: String, visibleText: String, durationMinutesText: String, dosageMgText: String, copayText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weight = weight
            self.visibleText = visibleText
            self.durationMinutesText = durationMinutesText
            self.dosageMgText = dosageMgText
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetScheduleView(_ item: OrderSetSchedule) -> OrderSetScheduleView {
        return OrderSetScheduleView(
            code: item.code,
            titleText: item.title,
            weight: String(format: "%.2f", item.weight),
            visibleText: "\(item.visible)",
            durationMinutesText: String(item.durationMinutes),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetScheduleViews(_ items: [OrderSetSchedule]) -> [OrderSetScheduleView] {
        var views: [OrderSetScheduleView] = []
        for item in items {
            views.append(toOrderSetScheduleView(item))
        }
        return views
    }

    static func sumOrderSetScheduleView(_ view: OrderSetScheduleView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedWeight + Double(parsedDurationMinutes) + parsedDosageMg
    }
}
