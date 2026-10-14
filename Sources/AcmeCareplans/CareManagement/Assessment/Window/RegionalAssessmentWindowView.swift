import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional assessment window.
    final class RegionalAssessmentWindowView {
        var code: String
        var name: String
        var expiresAtText: String
        var copay: String
        var updatedAt: String
        var phoneText: String
        var threshold: String
        var specialty: String
        var attempts: String
        var contactEmail: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, name: String, expiresAtText: String, copay: String, updatedAt: String, phoneText: String, threshold: String, specialty: String, attempts: String, contactEmail: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAtText = expiresAtText
            self.copay = copay
            self.updatedAt = updatedAt
            self.phoneText = phoneText
            self.threshold = threshold
            self.specialty = specialty
            self.attempts = attempts
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAssessmentWindowView(_ item: RegionalAssessmentWindow) -> RegionalAssessmentWindowView {
        return RegionalAssessmentWindowView(
            code: item.code,
            name: item.name,
            expiresAtText: String(item.expiresAt),
            copay: String(format: "%.2f", item.copay),
            updatedAt: String(item.updatedAt),
            phoneText: item.phone,
            threshold: String(format: "%.2f", item.threshold),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            attempts: String(item.attempts),
            contactEmail: item.contactEmail,
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAssessmentWindowViews(_ items: [RegionalAssessmentWindow]) -> [RegionalAssessmentWindowView] {
        var views: [RegionalAssessmentWindowView] = []
        for item in items {
            views.append(toRegionalAssessmentWindowView(item))
        }
        return views
    }

    static func sumRegionalAssessmentWindowView(_ view: RegionalAssessmentWindowView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedExpiresAt) + parsedCopay + Double(parsedUpdatedAt)
    }
}
