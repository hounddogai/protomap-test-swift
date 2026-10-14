import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient study metric.
    final class LenientStudyMetricView {
        var code: String
        var label: String
        var visitMinutes: String
        var archived: String
        var approved: String
        var updatedAtText: String
        var locale: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, archived: String, approved: String, updatedAtText: String, locale: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.approved = approved
            self.updatedAtText = updatedAtText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toLenientStudyMetricView(_ item: LenientStudyMetric) -> LenientStudyMetricView {
        return LenientStudyMetricView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            visitMinutes: String(item.visitMinutes),
            archived: "\(item.archived)",
            approved: "\(item.approved)",
            updatedAtText: String(item.updatedAt),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientStudyMetricViews(_ items: [LenientStudyMetric]) -> [LenientStudyMetricView] {
        var views: [LenientStudyMetricView] = []
        for item in items {
            views.append(toLenientStudyMetricView(item))
        }
        return views
    }

    static func sumLenientStudyMetricView(_ view: LenientStudyMetricView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedUpdatedAt)
    }
}
