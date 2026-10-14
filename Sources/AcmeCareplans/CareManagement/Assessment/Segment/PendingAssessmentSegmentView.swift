import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending assessment segment.
    final class PendingAssessmentSegmentView {
        var code: String
        var name: String
        var procedureCode: String
        var contactEmail: String
        var pinned: String
        var capacity: String
        var amount: String
        var attemptsText: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, name: String, procedureCode: String, contactEmail: String, pinned: String, capacity: String, amount: String, attemptsText: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.capacity = capacity
            self.amount = amount
            self.attemptsText = attemptsText
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAssessmentSegmentView(_ item: PendingAssessmentSegment) -> PendingAssessmentSegmentView {
        return PendingAssessmentSegmentView(
            code: item.code,
            name: item.name,
            procedureCode: item.procedureCode,
            contactEmail: item.contactEmail,
            pinned: "\(item.pinned)",
            capacity: String(item.capacity),
            amount: String(format: "%.2f", item.amount),
            attemptsText: String(item.attempts),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAssessmentSegmentViews(_ items: [PendingAssessmentSegment]) -> [PendingAssessmentSegmentView] {
        var views: [PendingAssessmentSegmentView] = []
        for item in items {
            views.append(toPendingAssessmentSegmentView(item))
        }
        return views
    }

    static func sumPendingAssessmentSegmentView(_ view: PendingAssessmentSegmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCapacity) + parsedAmount + Double(parsedAttempts)
    }
}
