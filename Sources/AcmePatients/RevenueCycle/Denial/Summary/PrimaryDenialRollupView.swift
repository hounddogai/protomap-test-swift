import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary denial rollup.
    final class PrimaryDenialRollupView {
        var code: String
        var labelText: String
        var phoneText: String
        var limitText: String
        var durationMinutesText: String
        var titleText: String
        var discount: String
        var quantity: String
        var statusLabel: String

        init(code: String, labelText: String, phoneText: String, limitText: String, durationMinutesText: String, titleText: String, discount: String, quantity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.phoneText = phoneText
            self.limitText = limitText
            self.durationMinutesText = durationMinutesText
            self.titleText = titleText
            self.discount = discount
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDenialRollupView(_ item: PrimaryDenialRollup) -> PrimaryDenialRollupView {
        return PrimaryDenialRollupView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            phoneText: item.phone,
            limitText: String(item.limit),
            durationMinutesText: String(item.durationMinutes),
            titleText: item.title,
            discount: String(format: "%.2f", item.discount),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDenialRollupViews(_ items: [PrimaryDenialRollup]) -> [PrimaryDenialRollupView] {
        var views: [PrimaryDenialRollupView] = []
        for item in items {
            views.append(toPrimaryDenialRollupView(item))
        }
        return views
    }

    static func sumPrimaryDenialRollupView(_ view: PrimaryDenialRollupView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedLimit) + Double(parsedDurationMinutes) + parsedDiscount
    }
}
