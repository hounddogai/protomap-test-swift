import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted authorization request.
    final class WeightedAuthorizationRequestView {
        var code: String
        var title: String
        var minimum: String
        var encounterID: String
        var acuity: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, encounterID: String, acuity: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.encounterID = encounterID
            self.acuity = acuity
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAuthorizationRequestView(_ item: WeightedAuthorizationRequest) -> WeightedAuthorizationRequestView {
        return WeightedAuthorizationRequestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            encounterID: item.encounterID,
            acuity: String(item.acuity),
            category: Kit.Text.truncate(item.category, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAuthorizationRequestViews(_ items: [WeightedAuthorizationRequest]) -> [WeightedAuthorizationRequestView] {
        var views: [WeightedAuthorizationRequestView] = []
        for item in items {
            views.append(toWeightedAuthorizationRequestView(item))
        }
        return views
    }

    static func sumWeightedAuthorizationRequestView(_ view: WeightedAuthorizationRequestView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMinimum + Double(parsedAcuity)
    }
}
