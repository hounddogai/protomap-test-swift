import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary referral milestone is in its life cycle.
    enum PrimaryReferralMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary referral milestone as the referral team keeps it.
    final class PrimaryReferralMilestone {
        var code: String
        var title: String
        var updatedAt: Int
        var capacity: Int
        var copay: Double
        var attempts: Int
        var status: PrimaryReferralMilestoneStatus

        init(code: String, title: String, updatedAt: Int, capacity: Int, copay: Double, attempts: Int, status: PrimaryReferralMilestoneStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.copay = copay
            self.attempts = attempts
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

        func canMoveTo(_ next: PrimaryReferralMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryReferralMilestoneStatus.approved || next == PrimaryReferralMilestoneStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryReferralMilestoneStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryReferralMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary referral milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return (Double(attempts) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryReferralMilestone {
            return PrimaryReferralMilestone(
                code: code,
                title: title,
                updatedAt: updatedAt,
                capacity: capacity,
                copay: copay,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary referral milestone in status proposed.
    static func newPrimaryReferralMilestone(_ code: String, title: String) -> PrimaryReferralMilestone {
        return PrimaryReferralMilestone(
            code: code,
            title: title,
            updatedAt: 0,
            capacity: 0,
            copay: 0.0,
            attempts: 0,
            status: PrimaryReferralMilestoneStatus.proposed
        )
    }
}
