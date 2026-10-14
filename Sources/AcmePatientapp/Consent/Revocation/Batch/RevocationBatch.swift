import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation batch is in its life cycle.
    enum RevocationBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A revocation batch. Its code is unique within a tenant.
    final class RevocationBatch {
        var code: String
        var label: String
        var attributes: [String: String]
        var tags: [String]
        var clinicianID: String
        var score: Double
        var status: RevocationBatchStatus

        init(code: String, label: String, attributes: [String: String], tags: [String], clinicianID: String, score: Double, status: RevocationBatchStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.tags = tags
            self.clinicianID = clinicianID
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == RevocationBatchStatus.scheduled || next == RevocationBatchStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RevocationBatchStatus.cancelled
            case .completed:
                return next == RevocationBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation batch") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func copyValue() -> RevocationBatch {
            return RevocationBatch(
                code: code,
                label: label,
                attributes: attributes,
                tags: tags,
                clinicianID: clinicianID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation batch in status planned.
    static func newRevocationBatch(_ code: String, label: String) -> RevocationBatch {
        return RevocationBatch(
            code: code,
            label: label,
            attributes: [:],
            tags: [],
            clinicianID: "",
            score: 0.0,
            status: RevocationBatchStatus.planned
        )
    }
}
