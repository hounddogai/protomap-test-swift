import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral milestone is in its life cycle.
    enum ReferralMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A referral milestone. Its code is unique within a tenant.
    final class ReferralMilestone {
        var code: String
        var name: String
        var country: String
        var unit: String
        var updatedAt: Int
        var status: ReferralMilestoneStatus

        init(code: String, name: String, country: String, unit: String, updatedAt: Int, status: ReferralMilestoneStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.unit = unit
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ReferralMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ReferralMilestoneStatus.inProgress
            case .inProgress:
                return next == ReferralMilestoneStatus.completed || next == ReferralMilestoneStatus.cancelled
            case .completed:
                return next == ReferralMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> ReferralMilestone {
            return ReferralMilestone(
                code: code,
                name: name,
                country: country,
                unit: unit,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a referral milestone in status planned.
    static func newReferralMilestone(_ code: String, name: String) -> ReferralMilestone {
        return ReferralMilestone(
            code: code,
            name: name,
            country: "",
            unit: "",
            updatedAt: 0,
            status: ReferralMilestoneStatus.planned
        )
    }
}
