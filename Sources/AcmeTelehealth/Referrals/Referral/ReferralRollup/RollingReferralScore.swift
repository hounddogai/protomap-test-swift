import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling referral score is in its life cycle.
    enum RollingReferralScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One rolling referral score, with what the planners need to act on it.
    final class RollingReferralScore {
        var code: String
        var label: String
        var attempts: Int
        var bed: String
        var title: String
        var segment: String
        var contactEmail: String
        var description: String
        var status: RollingReferralScoreStatus

        init(code: String, label: String, attempts: Int, bed: String, title: String, segment: String, contactEmail: String, description: String, status: RollingReferralScoreStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.bed = bed
            self.title = title
            self.segment = segment
            self.contactEmail = contactEmail
            self.description = description
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

        func canMoveTo(_ next: RollingReferralScoreStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingReferralScoreStatus.approved || next == RollingReferralScoreStatus.withdrawn
            case .approved:
                return next == RollingReferralScoreStatus.rejected || next == RollingReferralScoreStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingReferralScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling referral score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling referral score") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> RollingReferralScore {
            return RollingReferralScore(
                code: code,
                label: label,
                attempts: attempts,
                bed: bed,
                title: title,
                segment: segment,
                contactEmail: contactEmail,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling referral score in status proposed.
    static func newRollingReferralScore(_ code: String, label: String) -> RollingReferralScore {
        return RollingReferralScore(
            code: code,
            label: label,
            attempts: 0,
            bed: "",
            title: "",
            segment: "",
            contactEmail: "",
            description: "",
            status: RollingReferralScoreStatus.proposed
        )
    }
}
