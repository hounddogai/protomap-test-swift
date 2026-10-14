import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy credential schedule.
    final class LegacyCredentialScheduleView {
        var code: String
        var labelText: String
        var batchSize: String
        var procedureCodeText: String
        var bed: String
        var rate: String
        var ceiling: String
        var approved: String
        var statusLabel: String

        init(code: String, labelText: String, batchSize: String, procedureCodeText: String, bed: String, rate: String, ceiling: String, approved: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.batchSize = batchSize
            self.procedureCodeText = procedureCodeText
            self.bed = bed
            self.rate = rate
            self.ceiling = ceiling
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCredentialScheduleView(_ item: LegacyCredentialSchedule) -> LegacyCredentialScheduleView {
        return LegacyCredentialScheduleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            batchSize: String(item.batchSize),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            bed: item.bed,
            rate: String(format: "%.2f", item.rate),
            ceiling: String(format: "%.2f", item.ceiling),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCredentialScheduleViews(_ items: [LegacyCredentialSchedule]) -> [LegacyCredentialScheduleView] {
        var views: [LegacyCredentialScheduleView] = []
        for item in items {
            views.append(toLegacyCredentialScheduleView(item))
        }
        return views
    }

    static func sumLegacyCredentialScheduleView(_ view: LegacyCredentialScheduleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedBatchSize) + parsedRate + parsedCeiling
    }
}
