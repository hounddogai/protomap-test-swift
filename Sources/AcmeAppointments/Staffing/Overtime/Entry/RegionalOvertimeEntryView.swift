import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional overtime entry.
    final class RegionalOvertimeEntryView {
        var code: String
        var name: String
        var regionText: String
        var windowDaysText: String
        var procedureCode: String
        var rate: String
        var discountText: String
        var titleText: String
        var statusLabel: String

        init(code: String, name: String, regionText: String, windowDaysText: String, procedureCode: String, rate: String, discountText: String, titleText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.regionText = regionText
            self.windowDaysText = windowDaysText
            self.procedureCode = procedureCode
            self.rate = rate
            self.discountText = discountText
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOvertimeEntryView(_ item: RegionalOvertimeEntry) -> RegionalOvertimeEntryView {
        return RegionalOvertimeEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 120),
            regionText: item.region,
            windowDaysText: String(item.windowDays),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            rate: String(format: "%.2f", item.rate),
            discountText: String(format: "%.2f", item.discount),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOvertimeEntryViews(_ items: [RegionalOvertimeEntry]) -> [RegionalOvertimeEntryView] {
        var views: [RegionalOvertimeEntryView] = []
        for item in items {
            views.append(toRegionalOvertimeEntryView(item))
        }
        return views
    }

    static func sumRegionalOvertimeEntryView(_ view: RegionalOvertimeEntryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedWindowDays) + parsedRate + parsedDiscount
    }
}
