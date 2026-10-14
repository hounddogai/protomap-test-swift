import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary remittance schedule.
    final class PrimaryRemittanceScheduleView {
        var code: String
        var name: String
        var marginText: String
        var visible: String
        var reviewer: String
        var title: String
        var currency: String
        var statusLabel: String

        init(code: String, name: String, marginText: String, visible: String, reviewer: String, title: String, currency: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.marginText = marginText
            self.visible = visible
            self.reviewer = reviewer
            self.title = title
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRemittanceScheduleView(_ item: PrimaryRemittanceSchedule) -> PrimaryRemittanceScheduleView {
        return PrimaryRemittanceScheduleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            marginText: String(format: "%.2f", item.margin),
            visible: "\(item.visible)",
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            title: item.title,
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRemittanceScheduleViews(_ items: [PrimaryRemittanceSchedule]) -> [PrimaryRemittanceScheduleView] {
        var views: [PrimaryRemittanceScheduleView] = []
        for item in items {
            views.append(toPrimaryRemittanceScheduleView(item))
        }
        return views
    }

    static func sumPrimaryRemittanceScheduleView(_ view: PrimaryRemittanceScheduleView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
