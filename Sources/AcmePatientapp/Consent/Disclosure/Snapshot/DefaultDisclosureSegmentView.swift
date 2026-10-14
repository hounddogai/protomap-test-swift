import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default disclosure segment.
    final class DefaultDisclosureSegmentView {
        var code: String
        var label: String
        var maximum: String
        var endsAtText: String
        var specialtyText: String
        var expiresAt: String
        var summaryText: String
        var localeText: String
        var diagnosisCode: String
        var notesText: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, label: String, maximum: String, endsAtText: String, specialtyText: String, expiresAt: String, summaryText: String, localeText: String, diagnosisCode: String, notesText: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.endsAtText = endsAtText
            self.specialtyText = specialtyText
            self.expiresAt = expiresAt
            self.summaryText = summaryText
            self.localeText = localeText
            self.diagnosisCode = diagnosisCode
            self.notesText = notesText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDisclosureSegmentView(_ item: DefaultDisclosureSegment) -> DefaultDisclosureSegmentView {
        return DefaultDisclosureSegmentView(
            code: item.code,
            label: item.label,
            maximum: String(format: "%.2f", item.maximum),
            endsAtText: String(item.endsAt),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            expiresAt: String(item.expiresAt),
            summaryText: item.summary,
            localeText: item.locale,
            diagnosisCode: item.diagnosisCode,
            notesText: item.notes,
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDisclosureSegmentViews(_ items: [DefaultDisclosureSegment]) -> [DefaultDisclosureSegmentView] {
        var views: [DefaultDisclosureSegmentView] = []
        for item in items {
            views.append(toDefaultDisclosureSegmentView(item))
        }
        return views
    }

    static func sumDefaultDisclosureSegmentView(_ view: DefaultDisclosureSegmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMaximum + Double(parsedEndsAt) + Double(parsedExpiresAt)
    }
}
