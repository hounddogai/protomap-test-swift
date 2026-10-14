import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim metric.
    final class ClaimMetricView {
        var code: String
        var name: String
        var windowDaysText: String
        var copay: String
        var contactEmail: String
        var acuity: String
        var specialty: String
        var statusLabel: String

        init(code: String, name: String, windowDaysText: String, copay: String, contactEmail: String, acuity: String, specialty: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDaysText = windowDaysText
            self.copay = copay
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toClaimMetricView(_ item: ClaimMetric) -> ClaimMetricView {
        return ClaimMetricView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            windowDaysText: String(item.windowDays),
            copay: String(format: "%.2f", item.copay),
            contactEmail: item.contactEmail,
            acuity: String(item.acuity),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimMetricViews(_ items: [ClaimMetric]) -> [ClaimMetricView] {
        var views: [ClaimMetricView] = []
        for item in items {
            views.append(toClaimMetricView(item))
        }
        return views
    }

    static func sumClaimMetricView(_ view: ClaimMetricView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedWindowDays) + parsedCopay + Double(parsedAcuity)
    }
}
