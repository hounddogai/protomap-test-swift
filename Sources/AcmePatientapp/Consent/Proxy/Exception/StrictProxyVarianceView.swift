import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict proxy variance.
    final class StrictProxyVarianceView {
        var codeText: String
        var title: String
        var quantity: String
        var externalRef: String
        var label: String
        var ward: String
        var discount: String
        var durationMinutesText: String
        var statusLabel: String

        init(codeText: String, title: String, quantity: String, externalRef: String, label: String, ward: String, discount: String, durationMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.quantity = quantity
            self.externalRef = externalRef
            self.label = label
            self.ward = ward
            self.discount = discount
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictProxyVarianceView(_ item: StrictProxyVariance) -> StrictProxyVarianceView {
        return StrictProxyVarianceView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            quantity: String(item.quantity),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 40),
            ward: item.ward,
            discount: String(format: "%.2f", item.discount),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictProxyVarianceViews(_ items: [StrictProxyVariance]) -> [StrictProxyVarianceView] {
        var views: [StrictProxyVarianceView] = []
        for item in items {
            views.append(toStrictProxyVarianceView(item))
        }
        return views
    }

    static func sumStrictProxyVarianceView(_ view: StrictProxyVarianceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedQuantity) + parsedDiscount + Double(parsedDurationMinutes)
    }
}
