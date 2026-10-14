import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched cleaning override.
    final class BatchedCleaningOverrideView {
        var code: String
        var titleText: String
        var approved: String
        var diagnosisCodeText: String
        var pinnedText: String
        var segment: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, approved: String, diagnosisCodeText: String, pinnedText: String, segment: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approved = approved
            self.diagnosisCodeText = diagnosisCodeText
            self.pinnedText = pinnedText
            self.segment = segment
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCleaningOverrideView(_ item: BatchedCleaningOverride) -> BatchedCleaningOverrideView {
        return BatchedCleaningOverrideView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            approved: "\(item.approved)",
            diagnosisCodeText: item.diagnosisCode,
            pinnedText: "\(item.pinned)",
            segment: item.segment,
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCleaningOverrideViews(_ items: [BatchedCleaningOverride]) -> [BatchedCleaningOverrideView] {
        var views: [BatchedCleaningOverrideView] = []
        for item in items {
            views.append(toBatchedCleaningOverrideView(item))
        }
        return views
    }

    static func sumBatchedCleaningOverrideView(_ view: BatchedCleaningOverrideView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
