import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional revocation batch.
    final class RegionalRevocationBatchView {
        var code: String
        var title: String
        var costText: String
        var weight: String
        var visitMinutesText: String
        var locale: String
        var allergy: String
        var expiresAt: String
        var label: String
        var priorityText: String
        var statusLabel: String

        init(code: String, title: String, costText: String, weight: String, visitMinutesText: String, locale: String, allergy: String, expiresAt: String, label: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.costText = costText
            self.weight = weight
            self.visitMinutesText = visitMinutesText
            self.locale = locale
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.label = label
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRevocationBatchView(_ item: RegionalRevocationBatch) -> RegionalRevocationBatchView {
        return RegionalRevocationBatchView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            costText: String(format: "%.2f", item.cost),
            weight: String(format: "%.2f", item.weight),
            visitMinutesText: String(item.visitMinutes),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            allergy: item.allergy,
            expiresAt: String(item.expiresAt),
            label: item.label,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRevocationBatchViews(_ items: [RegionalRevocationBatch]) -> [RegionalRevocationBatchView] {
        var views: [RegionalRevocationBatchView] = []
        for item in items {
            views.append(toRegionalRevocationBatchView(item))
        }
        return views
    }

    static func sumRegionalRevocationBatchView(_ view: RegionalRevocationBatchView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedCost + parsedWeight + Double(parsedVisitMinutes)
    }
}
