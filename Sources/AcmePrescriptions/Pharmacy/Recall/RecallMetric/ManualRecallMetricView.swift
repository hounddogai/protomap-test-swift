import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall metric.
    final class ManualRecallMetricView {
        var code: String
        var labelText: String
        var summary: String
        var procedureCode: String
        var endsAtText: String
        var phoneText: String
        var allergy: String
        var statusLabel: String

        init(code: String, labelText: String, summary: String, procedureCode: String, endsAtText: String, phoneText: String, allergy: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.summary = summary
            self.procedureCode = procedureCode
            self.endsAtText = endsAtText
            self.phoneText = phoneText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallMetricView(_ item: ManualRecallMetric) -> ManualRecallMetricView {
        return ManualRecallMetricView(
            code: item.code,
            labelText: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            procedureCode: item.procedureCode,
            endsAtText: String(item.endsAt),
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallMetricViews(_ items: [ManualRecallMetric]) -> [ManualRecallMetricView] {
        var views: [ManualRecallMetricView] = []
        for item in items {
            views.append(toManualRecallMetricView(item))
        }
        return views
    }

    static func sumManualRecallMetricView(_ view: ManualRecallMetricView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
