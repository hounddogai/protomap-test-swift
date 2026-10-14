import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan estimate.
    final class AcuityPlanEstimateView {
        var code: String
        var labelText: String
        var ward: String
        var facilityText: String
        var versionText: String
        var statusLabel: String

        init(code: String, labelText: String, ward: String, facilityText: String, versionText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ward = ward
            self.facilityText = facilityText
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanEstimateView(_ item: AcuityPlanEstimate) -> AcuityPlanEstimateView {
        return AcuityPlanEstimateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            ward: Kit.Text.truncate(item.ward, limit: 40),
            facilityText: Kit.Text.truncate(item.facility, limit: 40),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanEstimateViews(_ items: [AcuityPlanEstimate]) -> [AcuityPlanEstimateView] {
        var views: [AcuityPlanEstimateView] = []
        for item in items {
            views.append(toAcuityPlanEstimateView(item))
        }
        return views
    }

    static func sumAcuityPlanEstimateView(_ view: AcuityPlanEstimateView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
