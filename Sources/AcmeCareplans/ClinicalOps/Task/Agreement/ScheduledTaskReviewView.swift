import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled task review.
    final class ScheduledTaskReviewView {
        var codeText: String
        var label: String
        var descriptionText: String
        var copay: String
        var minimumText: String
        var sequence: String
        var thresholdText: String
        var maximum: String
        var versionText: String
        var payerText: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, label: String, descriptionText: String, copay: String, minimumText: String, sequence: String, thresholdText: String, maximum: String, versionText: String, payerText: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.descriptionText = descriptionText
            self.copay = copay
            self.minimumText = minimumText
            self.sequence = sequence
            self.thresholdText = thresholdText
            self.maximum = maximum
            self.versionText = versionText
            self.payerText = payerText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledTaskReviewView(_ item: ScheduledTaskReview) -> ScheduledTaskReviewView {
        return ScheduledTaskReviewView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            descriptionText: item.description,
            copay: String(format: "%.2f", item.copay),
            minimumText: String(format: "%.2f", item.minimum),
            sequence: String(item.sequence),
            thresholdText: String(format: "%.2f", item.threshold),
            maximum: String(format: "%.2f", item.maximum),
            versionText: String(item.version),
            payerText: item.payer,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledTaskReviewViews(_ items: [ScheduledTaskReview]) -> [ScheduledTaskReviewView] {
        var views: [ScheduledTaskReviewView] = []
        for item in items {
            views.append(toScheduledTaskReviewView(item))
        }
        return views
    }

    static func sumScheduledTaskReviewView(_ view: ScheduledTaskReviewView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedCopay + parsedMinimum + Double(parsedSequence)
    }
}
