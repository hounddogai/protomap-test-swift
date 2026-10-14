import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched claim assignment.
    final class BatchedClaimAssignmentView {
        var code: String
        var titleText: String
        var windowDaysText: String
        var ratio: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, titleText: String, windowDaysText: String, ratio: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDaysText = windowDaysText
            self.ratio = ratio
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedClaimAssignmentView(_ item: BatchedClaimAssignment) -> BatchedClaimAssignmentView {
        return BatchedClaimAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            windowDaysText: String(item.windowDays),
            ratio: String(format: "%.2f", item.ratio),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedClaimAssignmentViews(_ items: [BatchedClaimAssignment]) -> [BatchedClaimAssignmentView] {
        var views: [BatchedClaimAssignmentView] = []
        for item in items {
            views.append(toBatchedClaimAssignmentView(item))
        }
        return views
    }

    static func sumBatchedClaimAssignmentView(_ view: BatchedClaimAssignmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedWindowDays) + parsedRatio + Double(parsedGraceDays)
    }
}
