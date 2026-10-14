import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive acuity plan estimate.
    final class AdaptiveAcuityPlanEstimateView {
        var code: String
        var labelText: String
        var channel: String
        var limit: String
        var patientRefText: String
        var refills: String
        var statusLabel: String

        init(code: String, labelText: String, channel: String, limit: String, patientRefText: String, refills: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.channel = channel
            self.limit = limit
            self.patientRefText = patientRefText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAcuityPlanEstimateView(_ item: AdaptiveAcuityPlanEstimate) -> AdaptiveAcuityPlanEstimateView {
        return AdaptiveAcuityPlanEstimateView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            channel: item.channel,
            limit: String(item.limit),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAcuityPlanEstimateViews(_ items: [AdaptiveAcuityPlanEstimate]) -> [AdaptiveAcuityPlanEstimateView] {
        var views: [AdaptiveAcuityPlanEstimateView] = []
        for item in items {
            views.append(toAdaptiveAcuityPlanEstimateView(item))
        }
        return views
    }

    static func sumAdaptiveAcuityPlanEstimateView(_ view: AdaptiveAcuityPlanEstimateView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedLimit) + Double(parsedRefills)
    }
}
