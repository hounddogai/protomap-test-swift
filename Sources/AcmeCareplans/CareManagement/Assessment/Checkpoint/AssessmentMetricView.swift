import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment metric.
    final class AssessmentMetricView {
        var code: String
        var nameText: String
        var specialty: String
        var weight: String
        var checksumText: String
        var expiresAt: String
        var externalRef: String
        var facility: String
        var statusLabel: String

        init(code: String, nameText: String, specialty: String, weight: String, checksumText: String, expiresAt: String, externalRef: String, facility: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialty = specialty
            self.weight = weight
            self.checksumText = checksumText
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentMetricView(_ item: AssessmentMetric) -> AssessmentMetricView {
        return AssessmentMetricView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            specialty: item.specialty,
            weight: String(format: "%.2f", item.weight),
            checksumText: item.checksum,
            expiresAt: String(item.expiresAt),
            externalRef: item.externalRef,
            facility: Kit.Text.truncate(item.facility, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentMetricViews(_ items: [AssessmentMetric]) -> [AssessmentMetricView] {
        var views: [AssessmentMetricView] = []
        for item in items {
            views.append(toAssessmentMetricView(item))
        }
        return views
    }

    static func sumAssessmentMetricView(_ view: AssessmentMetricView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedWeight + Double(parsedExpiresAt)
    }
}
