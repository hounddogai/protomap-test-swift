import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback charge entry.
    final class FallbackChargeEntryView {
        var code: String
        var title: String
        var endsAt: String
        var reviewer: String
        var sequenceText: String
        var ward: String
        var unit: String
        var procedureCode: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, title: String, endsAt: String, reviewer: String, sequenceText: String, ward: String, unit: String, procedureCode: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.sequenceText = sequenceText
            self.ward = ward
            self.unit = unit
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackChargeEntryView(_ item: FallbackChargeEntry) -> FallbackChargeEntryView {
        return FallbackChargeEntryView(
            code: item.code,
            title: item.title,
            endsAt: String(item.endsAt),
            reviewer: item.reviewer,
            sequenceText: String(item.sequence),
            ward: item.ward,
            unit: Kit.Text.truncate(item.unit, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackChargeEntryViews(_ items: [FallbackChargeEntry]) -> [FallbackChargeEntryView] {
        var views: [FallbackChargeEntryView] = []
        for item in items {
            views.append(toFallbackChargeEntryView(item))
        }
        return views
    }

    static func sumFallbackChargeEntryView(_ view: FallbackChargeEntryView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedSequence)
    }
}
