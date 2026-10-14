import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted acuity plan estimate.
    final class WeightedAcuityPlanEstimateView {
        var code: String
        var name: String
        var retries: String
        var reviewer: String
        var endsAt: String
        var revision: String
        var floorValue: String
        var threshold: String
        var facilityText: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, name: String, retries: String, reviewer: String, endsAt: String, revision: String, floorValue: String, threshold: String, facilityText: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retries = retries
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.revision = revision
            self.floorValue = floorValue
            self.threshold = threshold
            self.facilityText = facilityText
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAcuityPlanEstimateView(_ item: WeightedAcuityPlanEstimate) -> WeightedAcuityPlanEstimateView {
        return WeightedAcuityPlanEstimateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            retries: String(item.retries),
            reviewer: item.reviewer,
            endsAt: String(item.endsAt),
            revision: String(item.revision),
            floorValue: String(format: "%.2f", item.floorValue),
            threshold: String(format: "%.2f", item.threshold),
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAcuityPlanEstimateViews(_ items: [WeightedAcuityPlanEstimate]) -> [WeightedAcuityPlanEstimateView] {
        var views: [WeightedAcuityPlanEstimateView] = []
        for item in items {
            views.append(toWeightedAcuityPlanEstimateView(item))
        }
        return views
    }

    static func sumWeightedAcuityPlanEstimateView(_ view: WeightedAcuityPlanEstimateView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRetries) + Double(parsedEndsAt) + Double(parsedRevision)
    }
}
