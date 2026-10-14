import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered transfer record.
    final class TieredTransferRecordView {
        var code: String
        var title: String
        var phone: String
        var windowDaysText: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, phone: String, windowDaysText: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.windowDaysText = windowDaysText
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toTieredTransferRecordView(_ item: TieredTransferRecord) -> TieredTransferRecordView {
        return TieredTransferRecordView(
            code: item.code,
            title: item.title,
            phone: item.phone,
            windowDaysText: String(item.windowDays),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredTransferRecordViews(_ items: [TieredTransferRecord]) -> [TieredTransferRecordView] {
        var views: [TieredTransferRecordView] = []
        for item in items {
            views.append(toTieredTransferRecordView(item))
        }
        return views
    }

    static func sumTieredTransferRecordView(_ view: TieredTransferRecordView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedWindowDays) + parsedDiscount
    }
}
