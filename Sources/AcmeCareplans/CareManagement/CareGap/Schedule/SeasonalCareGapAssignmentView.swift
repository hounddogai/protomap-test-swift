import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal care gap assignment.
    final class SeasonalCareGapAssignmentView {
        var code: String
        var name: String
        var amount: String
        var acuity: String
        var expiresAt: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, amount: String, acuity: String, expiresAt: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.amount = amount
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareGapAssignmentView(_ item: SeasonalCareGapAssignment) -> SeasonalCareGapAssignmentView {
        return SeasonalCareGapAssignmentView(
            code: item.code,
            name: item.name,
            amount: String(format: "%.2f", item.amount),
            acuity: String(item.acuity),
            expiresAt: String(item.expiresAt),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareGapAssignmentViews(_ items: [SeasonalCareGapAssignment]) -> [SeasonalCareGapAssignmentView] {
        var views: [SeasonalCareGapAssignmentView] = []
        for item in items {
            views.append(toSeasonalCareGapAssignmentView(item))
        }
        return views
    }

    static func sumSeasonalCareGapAssignmentView(_ view: SeasonalCareGapAssignmentView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedAmount + Double(parsedAcuity) + Double(parsedExpiresAt)
    }
}
