import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol summary.
    final class CareProtocolSummaryView {
        var code: String
        var nameText: String
        var description: String
        var limit: String
        var unit: String
        var country: String
        var endsAt: String
        var externalRef: String
        var categoryText: String
        var ownerID: String
        var source: String
        var statusLabel: String

        init(code: String, nameText: String, description: String, limit: String, unit: String, country: String, endsAt: String, externalRef: String, categoryText: String, ownerID: String, source: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.description = description
            self.limit = limit
            self.unit = unit
            self.country = country
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.categoryText = categoryText
            self.ownerID = ownerID
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolSummaryView(_ item: CareProtocolSummary) -> CareProtocolSummaryView {
        return CareProtocolSummaryView(
            code: item.code,
            nameText: item.name,
            description: Kit.Text.truncate(item.description, limit: 80),
            limit: String(item.limit),
            unit: item.unit,
            country: item.country,
            endsAt: String(item.endsAt),
            externalRef: item.externalRef,
            categoryText: Kit.Text.truncate(item.category, limit: 80),
            ownerID: item.ownerID,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolSummaryViews(_ items: [CareProtocolSummary]) -> [CareProtocolSummaryView] {
        var views: [CareProtocolSummaryView] = []
        for item in items {
            views.append(toCareProtocolSummaryView(item))
        }
        return views
    }

    static func sumCareProtocolSummaryView(_ view: CareProtocolSummaryView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedLimit) + Double(parsedEndsAt)
    }
}
