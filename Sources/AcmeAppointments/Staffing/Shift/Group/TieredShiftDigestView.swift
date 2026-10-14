import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered shift digest.
    final class TieredShiftDigestView {
        var code: String
        var title: String
        var startsAt: String
        var quantityText: String
        var categoryText: String
        var contactEmail: String
        var unit: String
        var locale: String
        var priority: String
        var diagnosisCodeText: String
        var ratioText: String
        var statusLabel: String

        init(code: String, title: String, startsAt: String, quantityText: String, categoryText: String, contactEmail: String, unit: String, locale: String, priority: String, diagnosisCodeText: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.quantityText = quantityText
            self.categoryText = categoryText
            self.contactEmail = contactEmail
            self.unit = unit
            self.locale = locale
            self.priority = priority
            self.diagnosisCodeText = diagnosisCodeText
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredShiftDigestView(_ item: TieredShiftDigest) -> TieredShiftDigestView {
        return TieredShiftDigestView(
            code: item.code,
            title: item.title,
            startsAt: String(item.startsAt),
            quantityText: String(item.quantity),
            categoryText: item.category,
            contactEmail: item.contactEmail,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            locale: item.locale,
            priority: String(item.priority),
            diagnosisCodeText: item.diagnosisCode,
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredShiftDigestViews(_ items: [TieredShiftDigest]) -> [TieredShiftDigestView] {
        var views: [TieredShiftDigestView] = []
        for item in items {
            views.append(toTieredShiftDigestView(item))
        }
        return views
    }

    static func sumTieredShiftDigestView(_ view: TieredShiftDigestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedQuantity) + Double(parsedPriority)
    }
}
