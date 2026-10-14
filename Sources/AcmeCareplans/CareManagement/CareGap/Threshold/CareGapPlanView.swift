import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap plan.
    final class CareGapPlanView {
        var code: String
        var label: String
        var diagnosisCode: String
        var visibleText: String
        var priority: String
        var durationMinutes: String
        var weight: String
        var maximum: String
        var bedText: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, visibleText: String, priority: String, durationMinutes: String, weight: String, maximum: String, bedText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.visibleText = visibleText
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.maximum = maximum
            self.bedText = bedText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapPlanView(_ item: CareGapPlan) -> CareGapPlanView {
        return CareGapPlanView(
            code: item.code,
            label: item.label,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            visibleText: "\(item.visible)",
            priority: String(item.priority),
            durationMinutes: String(item.durationMinutes),
            weight: String(format: "%.2f", item.weight),
            maximum: String(format: "%.2f", item.maximum),
            bedText: item.bed,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapPlanViews(_ items: [CareGapPlan]) -> [CareGapPlanView] {
        var views: [CareGapPlanView] = []
        for item in items {
            views.append(toCareGapPlanView(item))
        }
        return views
    }

    static func sumCareGapPlanView(_ view: CareGapPlanView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedPriority) + Double(parsedDurationMinutes) + parsedWeight
    }
}
