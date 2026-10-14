import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer variance.
    final class TransferVarianceView {
        var code: String
        var titleText: String
        var locale: String
        var active: String
        var attempts: String
        var discountText: String
        var statusLabel: String

        init(code: String, titleText: String, locale: String, active: String, attempts: String, discountText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.locale = locale
            self.active = active
            self.attempts = attempts
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferVarianceView(_ item: TransferVariance) -> TransferVarianceView {
        return TransferVarianceView(
            code: item.code,
            titleText: item.title,
            locale: item.locale,
            active: "\(item.active)",
            attempts: String(item.attempts),
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferVarianceViews(_ items: [TransferVariance]) -> [TransferVarianceView] {
        var views: [TransferVarianceView] = []
        for item in items {
            views.append(toTransferVarianceView(item))
        }
        return views
    }

    static func sumTransferVarianceView(_ view: TransferVarianceView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedAttempts) + parsedDiscount
    }
}
