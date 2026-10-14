import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default risk score estimate.
    final class DefaultRiskScoreEstimateView {
        var code: String
        var labelText: String
        var encounterID: String
        var unit: String
        var bed: String
        var updatedAt: String
        var thresholdText: String
        var contactEmail: String
        var ward: String
        var archived: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, labelText: String, encounterID: String, unit: String, bed: String, updatedAt: String, thresholdText: String, contactEmail: String, ward: String, archived: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.encounterID = encounterID
            self.unit = unit
            self.bed = bed
            self.updatedAt = updatedAt
            self.thresholdText = thresholdText
            self.contactEmail = contactEmail
            self.ward = ward
            self.archived = archived
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRiskScoreEstimateView(_ item: DefaultRiskScoreEstimate) -> DefaultRiskScoreEstimateView {
        return DefaultRiskScoreEstimateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            encounterID: item.encounterID,
            unit: item.unit,
            bed: item.bed,
            updatedAt: String(item.updatedAt),
            thresholdText: String(format: "%.2f", item.threshold),
            contactEmail: item.contactEmail,
            ward: item.ward,
            archived: "\(item.archived)",
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRiskScoreEstimateViews(_ items: [DefaultRiskScoreEstimate]) -> [DefaultRiskScoreEstimateView] {
        var views: [DefaultRiskScoreEstimateView] = []
        for item in items {
            views.append(toDefaultRiskScoreEstimateView(item))
        }
        return views
    }

    static func sumDefaultRiskScoreEstimateView(_ view: DefaultRiskScoreEstimateView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedUpdatedAt) + parsedThreshold
    }
}
