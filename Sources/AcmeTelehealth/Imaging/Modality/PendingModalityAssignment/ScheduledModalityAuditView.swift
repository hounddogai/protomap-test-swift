import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled modality audit.
    final class ScheduledModalityAuditView {
        var code: String
        var titleText: String
        var batchSize: String
        var diagnosisCode: String
        var ratioText: String
        var timezone: String
        var statusLabel: String

        init(code: String, titleText: String, batchSize: String, diagnosisCode: String, ratioText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.ratioText = ratioText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledModalityAuditView(_ item: ScheduledModalityAudit) -> ScheduledModalityAuditView {
        return ScheduledModalityAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            batchSize: String(item.batchSize),
            diagnosisCode: item.diagnosisCode,
            ratioText: String(format: "%.2f", item.ratio),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledModalityAuditViews(_ items: [ScheduledModalityAudit]) -> [ScheduledModalityAuditView] {
        var views: [ScheduledModalityAuditView] = []
        for item in items {
            views.append(toScheduledModalityAuditView(item))
        }
        return views
    }

    static func sumScheduledModalityAuditView(_ view: ScheduledModalityAuditView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedBatchSize) + parsedRatio
    }
}
