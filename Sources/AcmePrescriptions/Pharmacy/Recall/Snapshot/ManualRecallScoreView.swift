import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall score.
    final class ManualRecallScoreView {
        var code: String
        var title: String
        var floorValue: String
        var createdAt: String
        var durationMinutes: String
        var unit: String
        var ratioText: String
        var description: String
        var attempts: String
        var labelText: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, createdAt: String, durationMinutes: String, unit: String, ratioText: String, description: String, attempts: String, labelText: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.ratioText = ratioText
            self.description = description
            self.attempts = attempts
            self.labelText = labelText
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallScoreView(_ item: ManualRecallScore) -> ManualRecallScoreView {
        return ManualRecallScoreView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            createdAt: String(item.createdAt),
            durationMinutes: String(item.durationMinutes),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            ratioText: String(format: "%.2f", item.ratio),
            description: item.description,
            attempts: String(item.attempts),
            labelText: item.label,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallScoreViews(_ items: [ManualRecallScore]) -> [ManualRecallScoreView] {
        var views: [ManualRecallScoreView] = []
        for item in items {
            views.append(toManualRecallScoreView(item))
        }
        return views
    }

    static func sumManualRecallScoreView(_ view: ManualRecallScoreView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedFloorValue + Double(parsedCreatedAt) + Double(parsedDurationMinutes)
    }
}
