import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped revocation summary.
    final class CappedRevocationSummaryView {
        var code: String
        var label: String
        var retries: String
        var startsAt: String
        var patientRef: String
        var endsAt: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, retries: String, startsAt: String, patientRef: String, endsAt: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.startsAt = startsAt
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRevocationSummaryView(_ item: CappedRevocationSummary) -> CappedRevocationSummaryView {
        return CappedRevocationSummaryView(
            code: item.code,
            label: item.label,
            retries: String(item.retries),
            startsAt: String(item.startsAt),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            endsAt: String(item.endsAt),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRevocationSummaryViews(_ items: [CappedRevocationSummary]) -> [CappedRevocationSummaryView] {
        var views: [CappedRevocationSummaryView] = []
        for item in items {
            views.append(toCappedRevocationSummaryView(item))
        }
        return views
    }

    static func sumCappedRevocationSummaryView(_ view: CappedRevocationSummaryView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRetries) + Double(parsedStartsAt) + Double(parsedEndsAt)
    }
}
