import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive care protocol estimate.
    final class AdaptiveCareProtocolEstimateView {
        var code: String
        var name: String
        var patientRefText: String
        var bed: String
        var summary: String
        var acuityText: String
        var statusLabel: String

        init(code: String, name: String, patientRefText: String, bed: String, summary: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRefText = patientRefText
            self.bed = bed
            self.summary = summary
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareProtocolEstimateView(_ item: AdaptiveCareProtocolEstimate) -> AdaptiveCareProtocolEstimateView {
        return AdaptiveCareProtocolEstimateView(
            code: item.code,
            name: item.name,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            bed: item.bed,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareProtocolEstimateViews(_ items: [AdaptiveCareProtocolEstimate]) -> [AdaptiveCareProtocolEstimateView] {
        var views: [AdaptiveCareProtocolEstimateView] = []
        for item in items {
            views.append(toAdaptiveCareProtocolEstimateView(item))
        }
        return views
    }

    static func sumAdaptiveCareProtocolEstimateView(_ view: AdaptiveCareProtocolEstimateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
