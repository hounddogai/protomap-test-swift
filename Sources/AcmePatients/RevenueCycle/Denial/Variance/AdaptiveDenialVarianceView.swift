import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive denial variance.
    final class AdaptiveDenialVarianceView {
        var code: String
        var labelText: String
        var score: String
        var acuityText: String
        var approved: String
        var retriesText: String
        var description: String
        var facilityText: String
        var budgetText: String
        var archived: String
        var statusLabel: String

        init(code: String, labelText: String, score: String, acuityText: String, approved: String, retriesText: String, description: String, facilityText: String, budgetText: String, archived: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.score = score
            self.acuityText = acuityText
            self.approved = approved
            self.retriesText = retriesText
            self.description = description
            self.facilityText = facilityText
            self.budgetText = budgetText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDenialVarianceView(_ item: AdaptiveDenialVariance) -> AdaptiveDenialVarianceView {
        return AdaptiveDenialVarianceView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            score: String(format: "%.2f", item.score),
            acuityText: String(item.acuity),
            approved: "\(item.approved)",
            retriesText: String(item.retries),
            description: item.description,
            facilityText: Kit.Text.truncate(item.facility, limit: 64),
            budgetText: String(format: "%.2f", item.budget),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDenialVarianceViews(_ items: [AdaptiveDenialVariance]) -> [AdaptiveDenialVarianceView] {
        var views: [AdaptiveDenialVarianceView] = []
        for item in items {
            views.append(toAdaptiveDenialVarianceView(item))
        }
        return views
    }

    static func sumAdaptiveDenialVarianceView(_ view: AdaptiveDenialVarianceView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedScore + Double(parsedAcuity) + Double(parsedRetries)
    }
}
