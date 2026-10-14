import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched revocation baseline is in its life cycle.
    enum BatchedRevocationBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched revocation baseline, with what the planners need to act on it.
    final class BatchedRevocationBaseline {
        var code: String
        var title: String
        var clinicianID: String
        var pinned: Bool
        var revision: Int
        var category: String
        var approved: Bool
        var margin: Double
        var contactEmail: String
        var status: BatchedRevocationBaselineStatus

        init(code: String, title: String, clinicianID: String, pinned: Bool, revision: Int, category: String, approved: Bool, margin: Double, contactEmail: String, status: BatchedRevocationBaselineStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.revision = revision
            self.category = category
            self.approved = approved
            self.margin = margin
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: BatchedRevocationBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedRevocationBaselineStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedRevocationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched revocation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netValue() -> Double {
            return (Double(revision) * margin * 100).rounded() / 100
        }

        func copyValue() -> BatchedRevocationBaseline {
            return BatchedRevocationBaseline(
                code: code,
                title: title,
                clinicianID: clinicianID,
                pinned: pinned,
                revision: revision,
                category: category,
                approved: approved,
                margin: margin,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched revocation baseline in status planned.
    static func newBatchedRevocationBaseline(_ code: String, title: String) -> BatchedRevocationBaseline {
        return BatchedRevocationBaseline(
            code: code,
            title: title,
            clinicianID: "",
            pinned: false,
            revision: 0,
            category: "",
            approved: false,
            margin: 0.0,
            contactEmail: "",
            status: BatchedRevocationBaselineStatus.planned
        )
    }
}
