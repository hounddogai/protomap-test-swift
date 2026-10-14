import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled acuity plan window.
    final class ScheduledAcuityPlanWindowView {
        var code: String
        var titleText: String
        var visible: String
        var batchSizeText: String
        var description: String
        var diagnosisCodeText: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, titleText: String, visible: String, batchSizeText: String, description: String, diagnosisCodeText: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visible = visible
            self.batchSizeText = batchSizeText
            self.description = description
            self.diagnosisCodeText = diagnosisCodeText
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAcuityPlanWindowView(_ item: ScheduledAcuityPlanWindow) -> ScheduledAcuityPlanWindowView {
        return ScheduledAcuityPlanWindowView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            visible: "\(item.visible)",
            batchSizeText: String(item.batchSize),
            description: Kit.Text.truncate(item.description, limit: 120),
            diagnosisCodeText: item.diagnosisCode,
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAcuityPlanWindowViews(_ items: [ScheduledAcuityPlanWindow]) -> [ScheduledAcuityPlanWindowView] {
        var views: [ScheduledAcuityPlanWindowView] = []
        for item in items {
            views.append(toScheduledAcuityPlanWindowView(item))
        }
        return views
    }

    static func sumScheduledAcuityPlanWindowView(_ view: ScheduledAcuityPlanWindowView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
