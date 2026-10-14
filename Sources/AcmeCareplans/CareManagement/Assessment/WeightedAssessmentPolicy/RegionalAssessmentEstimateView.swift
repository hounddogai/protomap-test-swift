import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional assessment estimate.
    final class RegionalAssessmentEstimateView {
        var code: String
        var name: String
        var timezoneText: String
        var externalRefText: String
        var clinicianID: String
        var acuity: String
        var minimum: String
        var specialty: String
        var wardText: String
        var budgetText: String
        var statusLabel: String

        init(code: String, name: String, timezoneText: String, externalRefText: String, clinicianID: String, acuity: String, minimum: String, specialty: String, wardText: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezoneText = timezoneText
            self.externalRefText = externalRefText
            self.clinicianID = clinicianID
            self.acuity = acuity
            self.minimum = minimum
            self.specialty = specialty
            self.wardText = wardText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAssessmentEstimateView(_ item: RegionalAssessmentEstimate) -> RegionalAssessmentEstimateView {
        return RegionalAssessmentEstimateView(
            code: item.code,
            name: item.name,
            timezoneText: item.timezone,
            externalRefText: item.externalRef,
            clinicianID: item.clinicianID,
            acuity: String(item.acuity),
            minimum: String(format: "%.2f", item.minimum),
            specialty: item.specialty,
            wardText: item.ward,
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAssessmentEstimateViews(_ items: [RegionalAssessmentEstimate]) -> [RegionalAssessmentEstimateView] {
        var views: [RegionalAssessmentEstimateView] = []
        for item in items {
            views.append(toRegionalAssessmentEstimateView(item))
        }
        return views
    }

    static func sumRegionalAssessmentEstimateView(_ view: RegionalAssessmentEstimateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAcuity) + parsedMinimum + parsedBudget
    }
}
