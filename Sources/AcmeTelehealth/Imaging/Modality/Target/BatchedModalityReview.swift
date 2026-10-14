import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched modality review is in its life cycle.
    enum BatchedModalityReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched modality review, with what the planners need to act on it.
    final class BatchedModalityReview {
        var code: String
        var name: String
        var attributes: [String: String]
        var ownerID: String
        var allergy: String
        var description: String
        var score: Double
        var status: BatchedModalityReviewStatus

        init(code: String, name: String, attributes: [String: String], ownerID: String, allergy: String, description: String, score: Double, status: BatchedModalityReviewStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.ownerID = ownerID
            self.allergy = allergy
            self.description = description
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedModalityReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedModalityReviewStatus.retired
            case .validated:
                return next == BatchedModalityReviewStatus.published
            case .published:
                return next == BatchedModalityReviewStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedModalityReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched modality review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> BatchedModalityReview {
            return BatchedModalityReview(
                code: code,
                name: name,
                attributes: attributes,
                ownerID: ownerID,
                allergy: allergy,
                description: description,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched modality review in status created.
    static func newBatchedModalityReview(_ code: String, name: String) -> BatchedModalityReview {
        return BatchedModalityReview(
            code: code,
            name: name,
            attributes: [:],
            ownerID: "",
            allergy: "",
            description: "",
            score: 0.0,
            status: BatchedModalityReviewStatus.created
        )
    }
}
