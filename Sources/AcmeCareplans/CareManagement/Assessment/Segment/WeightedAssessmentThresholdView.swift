import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted assessment threshold.
    final class WeightedAssessmentThresholdView {
        var code: String
        var label: String
        var rate: String
        var specialty: String
        var facility: String
        var ward: String
        var category: String
        var clinicianID: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, rate: String, specialty: String, facility: String, ward: String, category: String, clinicianID: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rate = rate
            self.specialty = specialty
            self.facility = facility
            self.ward = ward
            self.category = category
            self.clinicianID = clinicianID
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAssessmentThresholdView(_ item: WeightedAssessmentThreshold) -> WeightedAssessmentThresholdView {
        return WeightedAssessmentThresholdView(
            code: item.code,
            label: item.label,
            rate: String(format: "%.2f", item.rate),
            specialty: item.specialty,
            facility: Kit.Text.truncate(item.facility, limit: 80),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            category: item.category,
            clinicianID: item.clinicianID,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAssessmentThresholdViews(_ items: [WeightedAssessmentThreshold]) -> [WeightedAssessmentThresholdView] {
        var views: [WeightedAssessmentThresholdView] = []
        for item in items {
            views.append(toWeightedAssessmentThresholdView(item))
        }
        return views
    }

    static func sumWeightedAssessmentThresholdView(_ view: WeightedAssessmentThresholdView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
