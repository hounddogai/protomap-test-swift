import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive shift notice.
    final class AdaptiveShiftNoticeView {
        var code: String
        var title: String
        var ownerID: String
        var phone: String
        var pinned: String
        var name: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, phone: String, pinned: String, name: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.phone = phone
            self.pinned = pinned
            self.name = name
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveShiftNoticeView(_ item: AdaptiveShiftNotice) -> AdaptiveShiftNoticeView {
        return AdaptiveShiftNoticeView(
            code: item.code,
            title: item.title,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            phone: item.phone,
            pinned: "\(item.pinned)",
            name: Kit.Text.truncate(item.name, limit: 40),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveShiftNoticeViews(_ items: [AdaptiveShiftNotice]) -> [AdaptiveShiftNoticeView] {
        var views: [AdaptiveShiftNoticeView] = []
        for item in items {
            views.append(toAdaptiveShiftNoticeView(item))
        }
        return views
    }

    static func sumAdaptiveShiftNoticeView(_ view: AdaptiveShiftNoticeView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
