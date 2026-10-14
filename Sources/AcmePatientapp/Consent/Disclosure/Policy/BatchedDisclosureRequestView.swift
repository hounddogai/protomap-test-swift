import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched disclosure request.
    final class BatchedDisclosureRequestView {
        var code: String
        var title: String
        var reviewer: String
        var durationMinutes: String
        var retries: String
        var expiresAtText: String
        var specialtyText: String
        var segmentText: String
        var copay: String
        var budget: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, durationMinutes: String, retries: String, expiresAtText: String, specialtyText: String, segmentText: String, copay: String, budget: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.retries = retries
            self.expiresAtText = expiresAtText
            self.specialtyText = specialtyText
            self.segmentText = segmentText
            self.copay = copay
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDisclosureRequestView(_ item: BatchedDisclosureRequest) -> BatchedDisclosureRequestView {
        return BatchedDisclosureRequestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            durationMinutes: String(item.durationMinutes),
            retries: String(item.retries),
            expiresAtText: String(item.expiresAt),
            specialtyText: item.specialty,
            segmentText: item.segment,
            copay: String(format: "%.2f", item.copay),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDisclosureRequestViews(_ items: [BatchedDisclosureRequest]) -> [BatchedDisclosureRequestView] {
        var views: [BatchedDisclosureRequestView] = []
        for item in items {
            views.append(toBatchedDisclosureRequestView(item))
        }
        return views
    }

    static func sumBatchedDisclosureRequestView(_ view: BatchedDisclosureRequestView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRetries) + Double(parsedExpiresAt)
    }
}
