import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling panel plan.
    final class RollingPanelPlanView {
        var code: String
        var labelText: String
        var discount: String
        var clinicianID: String
        var facility: String
        var windowDays: String
        var createdAt: String
        var segment: String
        var threshold: String
        var statusLabel: String

        init(code: String, labelText: String, discount: String, clinicianID: String, facility: String, windowDays: String, createdAt: String, segment: String, threshold: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.discount = discount
            self.clinicianID = clinicianID
            self.facility = facility
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.segment = segment
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPanelPlanView(_ item: RollingPanelPlan) -> RollingPanelPlanView {
        return RollingPanelPlanView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            discount: String(format: "%.2f", item.discount),
            clinicianID: item.clinicianID,
            facility: item.facility,
            windowDays: String(item.windowDays),
            createdAt: String(item.createdAt),
            segment: item.segment,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPanelPlanViews(_ items: [RollingPanelPlan]) -> [RollingPanelPlanView] {
        var views: [RollingPanelPlanView] = []
        for item in items {
            views.append(toRollingPanelPlanView(item))
        }
        return views
    }

    static func sumRollingPanelPlanView(_ view: RollingPanelPlanView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedWindowDays) + Double(parsedCreatedAt)
    }
}
