import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan forecast.
    final class AcuityPlanForecastView {
        var code: String
        var titleText: String
        var dosageMg: String
        var wardText: String
        var summary: String
        var ratio: String
        var procedureCode: String
        var priorityText: String
        var checksum: String
        var statusLabel: String

        init(code: String, titleText: String, dosageMg: String, wardText: String, summary: String, ratio: String, procedureCode: String, priorityText: String, checksum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.dosageMg = dosageMg
            self.wardText = wardText
            self.summary = summary
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.priorityText = priorityText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanForecastView(_ item: AcuityPlanForecast) -> AcuityPlanForecastView {
        return AcuityPlanForecastView(
            code: item.code,
            titleText: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            wardText: item.ward,
            summary: item.summary,
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            priorityText: String(item.priority),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanForecastViews(_ items: [AcuityPlanForecast]) -> [AcuityPlanForecastView] {
        var views: [AcuityPlanForecastView] = []
        for item in items {
            views.append(toAcuityPlanForecastView(item))
        }
        return views
    }

    static func sumAcuityPlanForecastView(_ view: AcuityPlanForecastView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDosageMg + parsedRatio + Double(parsedPriority)
    }
}
