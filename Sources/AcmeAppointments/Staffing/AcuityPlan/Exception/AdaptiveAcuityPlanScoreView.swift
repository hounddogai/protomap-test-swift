import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive acuity plan score.
    final class AdaptiveAcuityPlanScoreView {
        var code: String
        var label: String
        var capacity: String
        var endsAt: String
        var country: String
        var sequence: String
        var windowDays: String
        var retries: String
        var ward: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, endsAt: String, country: String, sequence: String, windowDays: String, retries: String, ward: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.endsAt = endsAt
            self.country = country
            self.sequence = sequence
            self.windowDays = windowDays
            self.retries = retries
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAcuityPlanScoreView(_ item: AdaptiveAcuityPlanScore) -> AdaptiveAcuityPlanScoreView {
        return AdaptiveAcuityPlanScoreView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            capacity: String(item.capacity),
            endsAt: String(item.endsAt),
            country: item.country,
            sequence: String(item.sequence),
            windowDays: String(item.windowDays),
            retries: String(item.retries),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAcuityPlanScoreViews(_ items: [AdaptiveAcuityPlanScore]) -> [AdaptiveAcuityPlanScoreView] {
        var views: [AdaptiveAcuityPlanScoreView] = []
        for item in items {
            views.append(toAdaptiveAcuityPlanScoreView(item))
        }
        return views
    }

    static func sumAdaptiveAcuityPlanScoreView(_ view: AdaptiveAcuityPlanScoreView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedCapacity) + Double(parsedEndsAt) + Double(parsedSequence)
    }
}
