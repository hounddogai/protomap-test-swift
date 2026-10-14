import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness threshold.
    final class WitnessThresholdView {
        var codeText: String
        var title: String
        var discount: String
        var clinicianID: String
        var visitMinutesText: String
        var updatedAt: String
        var ownerID: String
        var diagnosisCode: String
        var refillsText: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, discount: String, clinicianID: String, visitMinutesText: String, updatedAt: String, ownerID: String, diagnosisCode: String, refillsText: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.discount = discount
            self.clinicianID = clinicianID
            self.visitMinutesText = visitMinutesText
            self.updatedAt = updatedAt
            self.ownerID = ownerID
            self.diagnosisCode = diagnosisCode
            self.refillsText = refillsText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessThresholdView(_ item: WitnessThreshold) -> WitnessThresholdView {
        return WitnessThresholdView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            discount: String(format: "%.2f", item.discount),
            clinicianID: item.clinicianID,
            visitMinutesText: String(item.visitMinutes),
            updatedAt: String(item.updatedAt),
            ownerID: item.ownerID,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            refillsText: String(item.refills),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessThresholdViews(_ items: [WitnessThreshold]) -> [WitnessThresholdView] {
        var views: [WitnessThresholdView] = []
        for item in items {
            views.append(toWitnessThresholdView(item))
        }
        return views
    }

    static func sumWitnessThresholdView(_ view: WitnessThresholdView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedDiscount + Double(parsedVisitMinutes) + Double(parsedUpdatedAt)
    }
}
