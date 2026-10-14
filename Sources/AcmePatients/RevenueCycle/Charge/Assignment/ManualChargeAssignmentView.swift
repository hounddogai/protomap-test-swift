import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual charge assignment.
    final class ManualChargeAssignmentView {
        var code: String
        var name: String
        var unit: String
        var descriptionText: String
        var specialty: String
        var score: String
        var statusLabel: String

        init(code: String, name: String, unit: String, descriptionText: String, specialty: String, score: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unit = unit
            self.descriptionText = descriptionText
            self.specialty = specialty
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toManualChargeAssignmentView(_ item: ManualChargeAssignment) -> ManualChargeAssignmentView {
        return ManualChargeAssignmentView(
            code: item.code,
            name: item.name,
            unit: item.unit,
            descriptionText: Kit.Text.truncate(item.description, limit: 64),
            specialty: item.specialty,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualChargeAssignmentViews(_ items: [ManualChargeAssignment]) -> [ManualChargeAssignmentView] {
        var views: [ManualChargeAssignmentView] = []
        for item in items {
            views.append(toManualChargeAssignmentView(item))
        }
        return views
    }

    static func sumManualChargeAssignmentView(_ view: ManualChargeAssignmentView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
