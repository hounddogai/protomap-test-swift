import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan checkpoint.
    final class AcuityPlanCheckpointView {
        var code: String
        var name: String
        var discount: String
        var floorValueText: String
        var bedText: String
        var title: String
        var attempts: String
        var createdAt: String
        var updatedAtText: String
        var approved: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, discount: String, floorValueText: String, bedText: String, title: String, attempts: String, createdAt: String, updatedAtText: String, approved: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discount = discount
            self.floorValueText = floorValueText
            self.bedText = bedText
            self.title = title
            self.attempts = attempts
            self.createdAt = createdAt
            self.updatedAtText = updatedAtText
            self.approved = approved
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanCheckpointView(_ item: AcuityPlanCheckpoint) -> AcuityPlanCheckpointView {
        return AcuityPlanCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            floorValueText: String(format: "%.2f", item.floorValue),
            bedText: item.bed,
            title: Kit.Text.truncate(item.title, limit: 80),
            attempts: String(item.attempts),
            createdAt: String(item.createdAt),
            updatedAtText: String(item.updatedAt),
            approved: "\(item.approved)",
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanCheckpointViews(_ items: [AcuityPlanCheckpoint]) -> [AcuityPlanCheckpointView] {
        var views: [AcuityPlanCheckpointView] = []
        for item in items {
            views.append(toAcuityPlanCheckpointView(item))
        }
        return views
    }

    static func sumAcuityPlanCheckpointView(_ view: AcuityPlanCheckpointView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDiscount + parsedFloorValue + Double(parsedAttempts)
    }
}
