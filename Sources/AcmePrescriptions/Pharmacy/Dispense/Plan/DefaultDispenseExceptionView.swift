import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default dispense exception.
    final class DefaultDispenseExceptionView {
        var code: String
        var name: String
        var visibleText: String
        var amountText: String
        var weight: String
        var locale: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, visibleText: String, amountText: String, weight: String, locale: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visibleText = visibleText
            self.amountText = amountText
            self.weight = weight
            self.locale = locale
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDispenseExceptionView(_ item: DefaultDispenseException) -> DefaultDispenseExceptionView {
        return DefaultDispenseExceptionView(
            code: item.code,
            name: item.name,
            visibleText: "\(item.visible)",
            amountText: String(format: "%.2f", item.amount),
            weight: String(format: "%.2f", item.weight),
            locale: item.locale,
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDispenseExceptionViews(_ items: [DefaultDispenseException]) -> [DefaultDispenseExceptionView] {
        var views: [DefaultDispenseExceptionView] = []
        for item in items {
            views.append(toDefaultDispenseExceptionView(item))
        }
        return views
    }

    static func sumDefaultDispenseExceptionView(_ view: DefaultDispenseExceptionView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedAmount + parsedWeight
    }
}
