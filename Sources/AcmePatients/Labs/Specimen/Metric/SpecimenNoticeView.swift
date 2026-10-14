import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen notice.
    final class SpecimenNoticeView {
        var code: String
        var label: String
        var retries: String
        var rateText: String
        var ceiling: String
        var localeText: String
        var margin: String
        var unit: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, retries: String, rateText: String, ceiling: String, localeText: String, margin: String, unit: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.rateText = rateText
            self.ceiling = ceiling
            self.localeText = localeText
            self.margin = margin
            self.unit = unit
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenNoticeView(_ item: SpecimenNotice) -> SpecimenNoticeView {
        return SpecimenNoticeView(
            code: item.code,
            label: item.label,
            retries: String(item.retries),
            rateText: String(format: "%.2f", item.rate),
            ceiling: String(format: "%.2f", item.ceiling),
            localeText: item.locale,
            margin: String(format: "%.2f", item.margin),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenNoticeViews(_ items: [SpecimenNotice]) -> [SpecimenNoticeView] {
        var views: [SpecimenNoticeView] = []
        for item in items {
            views.append(toSpecimenNoticeView(item))
        }
        return views
    }

    static func sumSpecimenNoticeView(_ view: SpecimenNoticeView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRetries) + parsedRate + parsedCeiling
    }
}
