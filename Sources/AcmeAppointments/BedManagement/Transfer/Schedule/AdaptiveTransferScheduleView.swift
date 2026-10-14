import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive transfer schedule.
    final class AdaptiveTransferScheduleView {
        var code: String
        var title: String
        var discount: String
        var phone: String
        var acuity: String
        var maximum: String
        var currency: String
        var revision: String
        var statusLabel: String

        init(code: String, title: String, discount: String, phone: String, acuity: String, maximum: String, currency: String, revision: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discount = discount
            self.phone = phone
            self.acuity = acuity
            self.maximum = maximum
            self.currency = currency
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveTransferScheduleView(_ item: AdaptiveTransferSchedule) -> AdaptiveTransferScheduleView {
        return AdaptiveTransferScheduleView(
            code: item.code,
            title: item.title,
            discount: String(format: "%.2f", item.discount),
            phone: item.phone,
            acuity: String(item.acuity),
            maximum: String(format: "%.2f", item.maximum),
            currency: item.currency,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveTransferScheduleViews(_ items: [AdaptiveTransferSchedule]) -> [AdaptiveTransferScheduleView] {
        var views: [AdaptiveTransferScheduleView] = []
        for item in items {
            views.append(toAdaptiveTransferScheduleView(item))
        }
        return views
    }

    static func sumAdaptiveTransferScheduleView(_ view: AdaptiveTransferScheduleView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedDiscount + Double(parsedAcuity) + parsedMaximum
    }
}
