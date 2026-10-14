import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap template.
    final class CareGapTemplateView {
        var code: String
        var label: String
        var patientRef: String
        var priority: String
        var summaryText: String
        var wardText: String
        var thresholdText: String
        var locale: String
        var acuityText: String
        var statusLabel: String

        init(code: String, label: String, patientRef: String, priority: String, summaryText: String, wardText: String, thresholdText: String, locale: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.priority = priority
            self.summaryText = summaryText
            self.wardText = wardText
            self.thresholdText = thresholdText
            self.locale = locale
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapTemplateView(_ item: CareGapTemplate) -> CareGapTemplateView {
        return CareGapTemplateView(
            code: item.code,
            label: item.label,
            patientRef: item.patientRef,
            priority: String(item.priority),
            summaryText: item.summary,
            wardText: item.ward,
            thresholdText: String(format: "%.2f", item.threshold),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapTemplateViews(_ items: [CareGapTemplate]) -> [CareGapTemplateView] {
        var views: [CareGapTemplateView] = []
        for item in items {
            views.append(toCareGapTemplateView(item))
        }
        return views
    }

    static func sumCareGapTemplateView(_ view: CareGapTemplateView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedPriority) + parsedThreshold + Double(parsedAcuity)
    }
}
