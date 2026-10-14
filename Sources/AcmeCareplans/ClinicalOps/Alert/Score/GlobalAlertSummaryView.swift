import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global alert summary.
    final class GlobalAlertSummaryView {
        var code: String
        var name: String
        var descriptionText: String
        var contactEmailText: String
        var segmentText: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, name: String, descriptionText: String, contactEmailText: String, segmentText: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.descriptionText = descriptionText
            self.contactEmailText = contactEmailText
            self.segmentText = segmentText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAlertSummaryView(_ item: GlobalAlertSummary) -> GlobalAlertSummaryView {
        return GlobalAlertSummaryView(
            code: item.code,
            name: item.name,
            descriptionText: item.description,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 120),
            segmentText: Kit.Text.truncate(item.segment, limit: 80),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAlertSummaryViews(_ items: [GlobalAlertSummary]) -> [GlobalAlertSummaryView] {
        var views: [GlobalAlertSummaryView] = []
        for item in items {
            views.append(toGlobalAlertSummaryView(item))
        }
        return views
    }

    static func sumGlobalAlertSummaryView(_ view: GlobalAlertSummaryView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
