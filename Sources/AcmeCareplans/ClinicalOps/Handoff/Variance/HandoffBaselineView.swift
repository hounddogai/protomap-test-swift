import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff baseline.
    final class HandoffBaselineView {
        var code: String
        var titleText: String
        var diagnosisCode: String
        var bed: String
        var rate: String
        var phone: String
        var statusLabel: String

        init(code: String, titleText: String, diagnosisCode: String, bed: String, rate: String, phone: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.diagnosisCode = diagnosisCode
            self.bed = bed
            self.rate = rate
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffBaselineView(_ item: HandoffBaseline) -> HandoffBaselineView {
        return HandoffBaselineView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            diagnosisCode: item.diagnosisCode,
            bed: item.bed,
            rate: String(format: "%.2f", item.rate),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffBaselineViews(_ items: [HandoffBaseline]) -> [HandoffBaselineView] {
        var views: [HandoffBaselineView] = []
        for item in items {
            views.append(toHandoffBaselineView(item))
        }
        return views
    }

    static func sumHandoffBaselineView(_ view: HandoffBaselineView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
