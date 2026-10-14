import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set score.
    final class OrderSetScoreView {
        var code: String
        var name: String
        var visitMinutes: String
        var ceiling: String
        var weightText: String
        var ward: String
        var endsAt: String
        var acuityText: String
        var threshold: String
        var statusLabel: String

        init(code: String, name: String, visitMinutes: String, ceiling: String, weightText: String, ward: String, endsAt: String, acuityText: String, threshold: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.weightText = weightText
            self.ward = ward
            self.endsAt = endsAt
            self.acuityText = acuityText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetScoreView(_ item: OrderSetScore) -> OrderSetScoreView {
        return OrderSetScoreView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            visitMinutes: String(item.visitMinutes),
            ceiling: String(format: "%.2f", item.ceiling),
            weightText: String(format: "%.2f", item.weight),
            ward: item.ward,
            endsAt: String(item.endsAt),
            acuityText: String(item.acuity),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetScoreViews(_ items: [OrderSetScore]) -> [OrderSetScoreView] {
        var views: [OrderSetScoreView] = []
        for item in items {
            views.append(toOrderSetScoreView(item))
        }
        return views
    }

    static func sumOrderSetScoreView(_ view: OrderSetScoreView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCeiling + parsedWeight
    }
}
