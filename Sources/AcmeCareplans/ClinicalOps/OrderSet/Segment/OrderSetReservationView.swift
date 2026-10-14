import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set reservation.
    final class OrderSetReservationView {
        var code: String
        var label: String
        var checksum: String
        var sourceText: String
        var title: String
        var ratioText: String
        var locale: String
        var description: String
        var category: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, sourceText: String, title: String, ratioText: String, locale: String, description: String, category: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.sourceText = sourceText
            self.title = title
            self.ratioText = ratioText
            self.locale = locale
            self.description = description
            self.category = category
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetReservationView(_ item: OrderSetReservation) -> OrderSetReservationView {
        return OrderSetReservationView(
            code: item.code,
            label: item.label,
            checksum: item.checksum,
            sourceText: item.source,
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            description: item.description,
            category: item.category,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetReservationViews(_ items: [OrderSetReservation]) -> [OrderSetReservationView] {
        var views: [OrderSetReservationView] = []
        for item in items {
            views.append(toOrderSetReservationView(item))
        }
        return views
    }

    static func sumOrderSetReservationView(_ view: OrderSetReservationView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedRatio + parsedDiscount
    }
}
