import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched eligibility draft is in its life cycle.
    enum BatchedEligibilityDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a batched eligibility draft and its current status.
    final class BatchedEligibilityDraft {
        var code: String
        var title: String
        var capacity: Int
        var summary: String
        var copay: Double
        var contactEmail: String
        var status: BatchedEligibilityDraftStatus

        init(code: String, title: String, capacity: Int, summary: String, copay: Double, contactEmail: String, status: BatchedEligibilityDraftStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.summary = summary
            self.copay = copay
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedEligibilityDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedEligibilityDraftStatus.approved || next == BatchedEligibilityDraftStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == BatchedEligibilityDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedEligibilityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched eligibility draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched eligibility draft") \(code)"
        }

        func effectiveTotal() -> Double {
            return (Double(capacity) * copay * 100).rounded() / 100
        }

        func copyValue() -> BatchedEligibilityDraft {
            return BatchedEligibilityDraft(
                code: code,
                title: title,
                capacity: capacity,
                summary: summary,
                copay: copay,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched eligibility draft in status proposed.
    static func newBatchedEligibilityDraft(_ code: String, title: String) -> BatchedEligibilityDraft {
        return BatchedEligibilityDraft(
            code: code,
            title: title,
            capacity: 0,
            summary: "",
            copay: 0.0,
            contactEmail: "",
            status: BatchedEligibilityDraftStatus.proposed
        )
    }
}
