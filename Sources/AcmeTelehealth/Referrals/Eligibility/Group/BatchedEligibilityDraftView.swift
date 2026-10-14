import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched eligibility draft.
    final class BatchedEligibilityDraftView {
        var code: String
        var title: String
        var capacity: String
        var summary: String
        var copayText: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, summary: String, copayText: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.summary = summary
            self.copayText = copayText
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedEligibilityDraftView(_ item: BatchedEligibilityDraft) -> BatchedEligibilityDraftView {
        return BatchedEligibilityDraftView(
            code: item.code,
            title: item.title,
            capacity: String(item.capacity),
            summary: item.summary,
            copayText: String(format: "%.2f", item.copay),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedEligibilityDraftViews(_ items: [BatchedEligibilityDraft]) -> [BatchedEligibilityDraftView] {
        var views: [BatchedEligibilityDraftView] = []
        for item in items {
            views.append(toBatchedEligibilityDraftView(item))
        }
        return views
    }

    static func sumBatchedEligibilityDraftView(_ view: BatchedEligibilityDraftView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedCapacity) + parsedCopay
    }
}
