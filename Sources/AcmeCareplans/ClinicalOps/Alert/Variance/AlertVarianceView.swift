import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert variance.
    final class AlertVarianceView {
        var code: String
        var label: String
        var visitMinutes: String
        var thresholdText: String
        var descriptionText: String
        var encounterID: String
        var name: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, thresholdText: String, descriptionText: String, encounterID: String, name: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.thresholdText = thresholdText
            self.descriptionText = descriptionText
            self.encounterID = encounterID
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toAlertVarianceView(_ item: AlertVariance) -> AlertVarianceView {
        return AlertVarianceView(
            code: item.code,
            label: item.label,
            visitMinutes: String(item.visitMinutes),
            thresholdText: String(format: "%.2f", item.threshold),
            descriptionText: Kit.Text.truncate(item.description, limit: 120),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertVarianceViews(_ items: [AlertVariance]) -> [AlertVarianceView] {
        var views: [AlertVarianceView] = []
        for item in items {
            views.append(toAlertVarianceView(item))
        }
        return views
    }

    static func sumAlertVarianceView(_ view: AlertVarianceView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedVisitMinutes) + parsedThreshold
    }
}
