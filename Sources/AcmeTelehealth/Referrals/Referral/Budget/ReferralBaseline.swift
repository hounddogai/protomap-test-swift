import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral baseline is in its life cycle.
    enum ReferralBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A referral baseline as the referral team keeps it.
    final class ReferralBaseline {
        var code: String
        var label: String
        var pinned: Bool
        var graceDays: Int
        var rate: Double
        var contactEmail: String
        var status: ReferralBaselineStatus

        init(code: String, label: String, pinned: Bool, graceDays: Int, rate: Double, contactEmail: String, status: ReferralBaselineStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.graceDays = graceDays
            self.rate = rate
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ReferralBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReferralBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((Double(graceDays) + rate) * 100).rounded() / 100
        }

        func copyValue() -> ReferralBaseline {
            return ReferralBaseline(
                code: code,
                label: label,
                pinned: pinned,
                graceDays: graceDays,
                rate: rate,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a referral baseline in status open.
    static func newReferralBaseline(_ code: String, label: String) -> ReferralBaseline {
        return ReferralBaseline(
            code: code,
            label: label,
            pinned: false,
            graceDays: 0,
            rate: 0.0,
            contactEmail: "",
            status: ReferralBaselineStatus.`open`
        )
    }
}
