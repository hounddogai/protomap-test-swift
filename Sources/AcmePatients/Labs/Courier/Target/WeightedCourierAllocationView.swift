import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted courier allocation.
    final class WeightedCourierAllocationView {
        var code: String
        var name: String
        var diagnosisCode: String
        var allergy: String
        var updatedAt: String
        var threshold: String
        var copay: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, allergy: String, updatedAt: String, threshold: String, copay: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCourierAllocationView(_ item: WeightedCourierAllocation) -> WeightedCourierAllocationView {
        return WeightedCourierAllocationView(
            code: item.code,
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            allergy: item.allergy,
            updatedAt: String(item.updatedAt),
            threshold: String(format: "%.2f", item.threshold),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCourierAllocationViews(_ items: [WeightedCourierAllocation]) -> [WeightedCourierAllocationView] {
        var views: [WeightedCourierAllocationView] = []
        for item in items {
            views.append(toWeightedCourierAllocationView(item))
        }
        return views
    }

    static func sumWeightedCourierAllocationView(_ view: WeightedCourierAllocationView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedUpdatedAt) + parsedThreshold + parsedCopay
    }
}
