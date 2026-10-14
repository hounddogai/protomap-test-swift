import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility metric.
    final class EligibilityMetricView {
        var code: String
        var titleText: String
        var startsAt: String
        var dosageMgText: String
        var phone: String
        var patientRefText: String
        var source: String
        var checksum: String
        var specialty: String
        var statusLabel: String

        init(code: String, titleText: String, startsAt: String, dosageMgText: String, phone: String, patientRefText: String, source: String, checksum: String, specialty: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.startsAt = startsAt
            self.dosageMgText = dosageMgText
            self.phone = phone
            self.patientRefText = patientRefText
            self.source = source
            self.checksum = checksum
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityMetricView(_ item: EligibilityMetric) -> EligibilityMetricView {
        return EligibilityMetricView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            startsAt: String(item.startsAt),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            phone: item.phone,
            patientRefText: item.patientRef,
            source: Kit.Text.truncate(item.source, limit: 120),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityMetricViews(_ items: [EligibilityMetric]) -> [EligibilityMetricView] {
        var views: [EligibilityMetricView] = []
        for item in items {
            views.append(toEligibilityMetricView(item))
        }
        return views
    }

    static func sumEligibilityMetricView(_ view: EligibilityMetricView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedStartsAt) + parsedDosageMg
    }
}
