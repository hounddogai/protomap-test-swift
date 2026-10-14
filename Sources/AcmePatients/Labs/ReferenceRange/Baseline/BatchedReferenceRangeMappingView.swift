import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched reference range mapping.
    final class BatchedReferenceRangeMappingView {
        var code: String
        var nameText: String
        var sequence: String
        var priority: String
        var locale: String
        var createdAt: String
        var refills: String
        var pinned: String
        var statusLabel: String

        init(code: String, nameText: String, sequence: String, priority: String, locale: String, createdAt: String, refills: String, pinned: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.sequence = sequence
            self.priority = priority
            self.locale = locale
            self.createdAt = createdAt
            self.refills = refills
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedReferenceRangeMappingView(_ item: BatchedReferenceRangeMapping) -> BatchedReferenceRangeMappingView {
        return BatchedReferenceRangeMappingView(
            code: item.code,
            nameText: item.name,
            sequence: String(item.sequence),
            priority: String(item.priority),
            locale: item.locale,
            createdAt: String(item.createdAt),
            refills: String(item.refills),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedReferenceRangeMappingViews(_ items: [BatchedReferenceRangeMapping]) -> [BatchedReferenceRangeMappingView] {
        var views: [BatchedReferenceRangeMappingView] = []
        for item in items {
            views.append(toBatchedReferenceRangeMappingView(item))
        }
        return views
    }

    static func sumBatchedReferenceRangeMappingView(_ view: BatchedReferenceRangeMappingView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedSequence) + Double(parsedPriority) + Double(parsedCreatedAt)
    }
}
