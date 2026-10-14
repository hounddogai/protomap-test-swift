import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal program segment.
    final class SeasonalProgramSegmentView {
        var codeText: String
        var label: String
        var segment: String
        var weight: String
        var contactEmail: String
        var rate: String
        var categoryText: String
        var source: String
        var encounterID: String
        var descriptionText: String
        var unitText: String
        var statusLabel: String

        init(codeText: String, label: String, segment: String, weight: String, contactEmail: String, rate: String, categoryText: String, source: String, encounterID: String, descriptionText: String, unitText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.segment = segment
            self.weight = weight
            self.contactEmail = contactEmail
            self.rate = rate
            self.categoryText = categoryText
            self.source = source
            self.encounterID = encounterID
            self.descriptionText = descriptionText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalProgramSegmentView(_ item: SeasonalProgramSegment) -> SeasonalProgramSegmentView {
        return SeasonalProgramSegmentView(
            codeText: item.code,
            label: item.label,
            segment: item.segment,
            weight: String(format: "%.2f", item.weight),
            contactEmail: item.contactEmail,
            rate: String(format: "%.2f", item.rate),
            categoryText: item.category,
            source: item.source,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            descriptionText: item.description,
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalProgramSegmentViews(_ items: [SeasonalProgramSegment]) -> [SeasonalProgramSegmentView] {
        var views: [SeasonalProgramSegmentView] = []
        for item in items {
            views.append(toSeasonalProgramSegmentView(item))
        }
        return views
    }

    static func sumSeasonalProgramSegmentView(_ view: SeasonalProgramSegmentView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedWeight + parsedRate
    }
}
