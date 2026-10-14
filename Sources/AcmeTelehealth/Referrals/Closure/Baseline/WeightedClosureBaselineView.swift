import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted closure baseline.
    final class WeightedClosureBaselineView {
        var code: String
        var name: String
        var summaryText: String
        var visible: String
        var phone: String
        var diagnosisCode: String
        var notes: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, summaryText: String, visible: String, phone: String, diagnosisCode: String, notes: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.summaryText = summaryText
            self.visible = visible
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedClosureBaselineView(_ item: WeightedClosureBaseline) -> WeightedClosureBaselineView {
        return WeightedClosureBaselineView(
            code: item.code,
            name: item.name,
            summaryText: item.summary,
            visible: "\(item.visible)",
            phone: item.phone,
            diagnosisCode: item.diagnosisCode,
            notes: item.notes,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedClosureBaselineViews(_ items: [WeightedClosureBaseline]) -> [WeightedClosureBaselineView] {
        var views: [WeightedClosureBaselineView] = []
        for item in items {
            views.append(toWeightedClosureBaselineView(item))
        }
        return views
    }

    static func sumWeightedClosureBaselineView(_ view: WeightedClosureBaselineView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
