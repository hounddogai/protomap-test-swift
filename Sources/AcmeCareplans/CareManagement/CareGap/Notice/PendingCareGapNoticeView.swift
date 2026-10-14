import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending care gap notice.
    final class PendingCareGapNoticeView {
        var code: String
        var label: String
        var threshold: String
        var timezone: String
        var phoneText: String
        var retries: String
        var priority: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, timezone: String, phoneText: String, retries: String, priority: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.timezone = timezone
            self.phoneText = phoneText
            self.retries = retries
            self.priority = priority
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCareGapNoticeView(_ item: PendingCareGapNotice) -> PendingCareGapNoticeView {
        return PendingCareGapNoticeView(
            code: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            timezone: item.timezone,
            phoneText: item.phone,
            retries: String(item.retries),
            priority: String(item.priority),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCareGapNoticeViews(_ items: [PendingCareGapNotice]) -> [PendingCareGapNoticeView] {
        var views: [PendingCareGapNoticeView] = []
        for item in items {
            views.append(toPendingCareGapNoticeView(item))
        }
        return views
    }

    static func sumPendingCareGapNoticeView(_ view: PendingCareGapNoticeView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedThreshold + Double(parsedRetries) + Double(parsedPriority)
    }
}
