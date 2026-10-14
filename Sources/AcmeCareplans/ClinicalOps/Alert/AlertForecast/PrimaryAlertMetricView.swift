import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary alert metric.
    final class PrimaryAlertMetricView {
        var code: String
        var title: String
        var refills: String
        var encounterID: String
        var acuityText: String
        var category: String
        var sequenceText: String
        var unitText: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, title: String, refills: String, encounterID: String, acuityText: String, category: String, sequenceText: String, unitText: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refills = refills
            self.encounterID = encounterID
            self.acuityText = acuityText
            self.category = category
            self.sequenceText = sequenceText
            self.unitText = unitText
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAlertMetricView(_ item: PrimaryAlertMetric) -> PrimaryAlertMetricView {
        return PrimaryAlertMetricView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            refills: String(item.refills),
            encounterID: item.encounterID,
            acuityText: String(item.acuity),
            category: item.category,
            sequenceText: String(item.sequence),
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAlertMetricViews(_ items: [PrimaryAlertMetric]) -> [PrimaryAlertMetricView] {
        var views: [PrimaryAlertMetricView] = []
        for item in items {
            views.append(toPrimaryAlertMetricView(item))
        }
        return views
    }

    static func sumPrimaryAlertMetricView(_ view: PrimaryAlertMetricView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedRefills) + Double(parsedAcuity) + Double(parsedSequence)
    }
}
