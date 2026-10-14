import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global rounding schedule.
    final class GlobalRoundingScheduleView {
        var code: String
        var labelText: String
        var phone: String
        var titleText: String
        var ratio: String
        var windowDays: String
        var retriesText: String
        var dosageMg: String
        var description: String
        var payerText: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, labelText: String, phone: String, titleText: String, ratio: String, windowDays: String, retriesText: String, dosageMg: String, description: String, payerText: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.phone = phone
            self.titleText = titleText
            self.ratio = ratio
            self.windowDays = windowDays
            self.retriesText = retriesText
            self.dosageMg = dosageMg
            self.description = description
            self.payerText = payerText
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRoundingScheduleView(_ item: GlobalRoundingSchedule) -> GlobalRoundingScheduleView {
        return GlobalRoundingScheduleView(
            code: item.code,
            labelText: item.label,
            phone: Kit.Text.truncate(item.phone, limit: 64),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            windowDays: String(item.windowDays),
            retriesText: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            description: item.description,
            payerText: Kit.Text.truncate(item.payer, limit: 40),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRoundingScheduleViews(_ items: [GlobalRoundingSchedule]) -> [GlobalRoundingScheduleView] {
        var views: [GlobalRoundingScheduleView] = []
        for item in items {
            views.append(toGlobalRoundingScheduleView(item))
        }
        return views
    }

    static func sumGlobalRoundingScheduleView(_ view: GlobalRoundingScheduleView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedRatio + Double(parsedWindowDays) + Double(parsedRetries)
    }
}
