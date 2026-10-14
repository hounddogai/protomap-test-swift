import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched credential review is in its life cycle.
    enum BatchedCredentialReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One batched credential review, with what the planners need to act on it.
    final class BatchedCredentialReview {
        var code: String
        var label: String
        var dosageMg: Double
        var ceiling: Double
        var sequence: Int
        var updatedAt: Int
        var createdAt: Int
        var externalRef: String
        var phone: String
        var expiresAt: Int
        var status: BatchedCredentialReviewStatus

        init(code: String, label: String, dosageMg: Double, ceiling: Double, sequence: Int, updatedAt: Int, createdAt: Int, externalRef: String, phone: String, expiresAt: Int, status: BatchedCredentialReviewStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.ceiling = ceiling
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.phone = phone
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedCredentialReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BatchedCredentialReviewStatus.reopened
            case .resolved:
                return next == BatchedCredentialReviewStatus.reopened || next == BatchedCredentialReviewStatus.archived
            case .reopened:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCredentialReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched credential review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(expiresAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCredentialReview {
            return BatchedCredentialReview(
                code: code,
                label: label,
                dosageMg: dosageMg,
                ceiling: ceiling,
                sequence: sequence,
                updatedAt: updatedAt,
                createdAt: createdAt,
                externalRef: externalRef,
                phone: phone,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched credential review in status open.
    static func newBatchedCredentialReview(_ code: String, label: String) -> BatchedCredentialReview {
        return BatchedCredentialReview(
            code: code,
            label: label,
            dosageMg: 0.0,
            ceiling: 0.0,
            sequence: 0,
            updatedAt: 0,
            createdAt: 0,
            externalRef: "",
            phone: "",
            expiresAt: 0,
            status: BatchedCredentialReviewStatus.`open`
        )
    }
}
