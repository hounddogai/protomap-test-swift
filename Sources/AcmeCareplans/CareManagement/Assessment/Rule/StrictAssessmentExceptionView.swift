import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict assessment exception.
    final class StrictAssessmentExceptionView {
        var code: String
        var labelText: String
        var channel: String
        var facility: String
        var updatedAt: String
        var thresholdText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, labelText: String, channel: String, facility: String, updatedAt: String, thresholdText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.channel = channel
            self.facility = facility
            self.updatedAt = updatedAt
            self.thresholdText = thresholdText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAssessmentExceptionView(_ item: StrictAssessmentException) -> StrictAssessmentExceptionView {
        return StrictAssessmentExceptionView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            channel: item.channel,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            updatedAt: String(item.updatedAt),
            thresholdText: String(format: "%.2f", item.threshold),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAssessmentExceptionViews(_ items: [StrictAssessmentException]) -> [StrictAssessmentExceptionView] {
        var views: [StrictAssessmentExceptionView] = []
        for item in items {
            views.append(toStrictAssessmentExceptionView(item))
        }
        return views
    }

    static func sumStrictAssessmentExceptionView(_ view: StrictAssessmentExceptionView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedUpdatedAt) + parsedThreshold + parsedFloorValue
    }
}
