import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched referral assignment is in its life cycle.
    enum BatchedReferralAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched referral assignment, with what the planners need to act on it.
    final class BatchedReferralAssignment {
        var code: String
        var label: String
        var version: Int
        var source: String
        var reviewer: String
        var contactEmail: String
        var status: BatchedReferralAssignmentStatus

        init(code: String, label: String, version: Int, source: String, reviewer: String, contactEmail: String, status: BatchedReferralAssignmentStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.source = source
            self.reviewer = reviewer
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedReferralAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedReferralAssignmentStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BatchedReferralAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched referral assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> BatchedReferralAssignment {
            return BatchedReferralAssignment(
                code: code,
                label: label,
                version: version,
                source: source,
                reviewer: reviewer,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched referral assignment in status requested.
    static func newBatchedReferralAssignment(_ code: String, label: String) -> BatchedReferralAssignment {
        return BatchedReferralAssignment(
            code: code,
            label: label,
            version: 0,
            source: "",
            reviewer: "",
            contactEmail: "",
            status: BatchedReferralAssignmentStatus.requested
        )
    }
}
