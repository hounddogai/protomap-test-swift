import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary task claim is in its life cycle.
    enum PrimaryTaskClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One primary task claim, with what the planners need to act on it.
    final class PrimaryTaskClaim {
        var code: String
        var label: String
        var timezone: String
        var checksum: String
        var refills: Int
        var status: PrimaryTaskClaimStatus

        init(code: String, label: String, timezone: String, checksum: String, refills: Int, status: PrimaryTaskClaimStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.checksum = checksum
            self.refills = refills
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

        func canMoveTo(_ next: PrimaryTaskClaimStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryTaskClaimStatus.reopened
            case .inReview:
                return next == PrimaryTaskClaimStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryTaskClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary task claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary task claim") \(code)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> PrimaryTaskClaim {
            return PrimaryTaskClaim(
                code: code,
                label: label,
                timezone: timezone,
                checksum: checksum,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary task claim in status open.
    static func newPrimaryTaskClaim(_ code: String, label: String) -> PrimaryTaskClaim {
        return PrimaryTaskClaim(
            code: code,
            label: label,
            timezone: "",
            checksum: "",
            refills: 0,
            status: PrimaryTaskClaimStatus.`open`
        )
    }
}
