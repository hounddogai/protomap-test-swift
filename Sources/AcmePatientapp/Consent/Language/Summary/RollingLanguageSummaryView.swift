import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling language summary.
    final class RollingLanguageSummaryView {
        var code: String
        var label: String
        var batchSizeText: String
        var acuity: String
        var facility: String
        var endsAt: String
        var locale: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, batchSizeText: String, acuity: String, facility: String, endsAt: String, locale: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSizeText = batchSizeText
            self.acuity = acuity
            self.facility = facility
            self.endsAt = endsAt
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRollingLanguageSummaryView(_ item: RollingLanguageSummary) -> RollingLanguageSummaryView {
        return RollingLanguageSummaryView(
            code: item.code,
            label: item.label,
            batchSizeText: String(item.batchSize),
            acuity: String(item.acuity),
            facility: item.facility,
            endsAt: String(item.endsAt),
            locale: item.locale,
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingLanguageSummaryViews(_ items: [RollingLanguageSummary]) -> [RollingLanguageSummaryView] {
        var views: [RollingLanguageSummaryView] = []
        for item in items {
            views.append(toRollingLanguageSummaryView(item))
        }
        return views
    }

    static func sumRollingLanguageSummaryView(_ view: RollingLanguageSummaryView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAcuity) + Double(parsedEndsAt)
    }
}
