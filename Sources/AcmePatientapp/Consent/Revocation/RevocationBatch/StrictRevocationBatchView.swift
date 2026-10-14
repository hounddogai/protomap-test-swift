import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict revocation batch.
    final class StrictRevocationBatchView {
        var code: String
        var label: String
        var priority: String
        var revisionText: String
        var sequence: String
        var quantity: String
        var reviewer: String
        var country: String
        var contactEmail: String
        var rate: String
        var statusLabel: String

        init(code: String, label: String, priority: String, revisionText: String, sequence: String, quantity: String, reviewer: String, country: String, contactEmail: String, rate: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.priority = priority
            self.revisionText = revisionText
            self.sequence = sequence
            self.quantity = quantity
            self.reviewer = reviewer
            self.country = country
            self.contactEmail = contactEmail
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRevocationBatchView(_ item: StrictRevocationBatch) -> StrictRevocationBatchView {
        return StrictRevocationBatchView(
            code: item.code,
            label: item.label,
            priority: String(item.priority),
            revisionText: String(item.revision),
            sequence: String(item.sequence),
            quantity: String(item.quantity),
            reviewer: item.reviewer,
            country: item.country,
            contactEmail: item.contactEmail,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRevocationBatchViews(_ items: [StrictRevocationBatch]) -> [StrictRevocationBatchView] {
        var views: [StrictRevocationBatchView] = []
        for item in items {
            views.append(toStrictRevocationBatchView(item))
        }
        return views
    }

    static func sumStrictRevocationBatchView(_ view: StrictRevocationBatchView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedPriority) + Double(parsedRevision) + Double(parsedSequence)
    }
}
