import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted claim assignment.
    final class WeightedClaimAssignmentView {
        var code: String
        var title: String
        var updatedAt: String
        var discount: String
        var windowDays: String
        var ratio: String
        var batchSize: String
        var ward: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, discount: String, windowDays: String, ratio: String, batchSize: String, ward: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.discount = discount
            self.windowDays = windowDays
            self.ratio = ratio
            self.batchSize = batchSize
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedClaimAssignmentView(_ item: WeightedClaimAssignment) -> WeightedClaimAssignmentView {
        return WeightedClaimAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            updatedAt: String(item.updatedAt),
            discount: String(format: "%.2f", item.discount),
            windowDays: String(item.windowDays),
            ratio: String(format: "%.2f", item.ratio),
            batchSize: String(item.batchSize),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedClaimAssignmentViews(_ items: [WeightedClaimAssignment]) -> [WeightedClaimAssignmentView] {
        var views: [WeightedClaimAssignmentView] = []
        for item in items {
            views.append(toWeightedClaimAssignmentView(item))
        }
        return views
    }

    static func sumWeightedClaimAssignmentView(_ view: WeightedClaimAssignmentView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedUpdatedAt) + parsedDiscount + Double(parsedWindowDays)
    }
}
