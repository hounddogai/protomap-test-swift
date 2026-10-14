import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral plan is in its life cycle.
    enum ReferralPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a referral plan and its current status.
    final class ReferralPlan {
        var code: String
        var title: String
        var approved: Bool
        var revision: Int
        var ownerID: String
        var updatedAt: Int
        var graceDays: Int
        var status: ReferralPlanStatus

        init(code: String, title: String, approved: Bool, revision: Int, ownerID: String, updatedAt: Int, graceDays: Int, status: ReferralPlanStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.revision = revision
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ReferralPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ReferralPlan {
            return ReferralPlan(
                code: code,
                title: title,
                approved: approved,
                revision: revision,
                ownerID: ownerID,
                updatedAt: updatedAt,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a referral plan in status new.
    static func newReferralPlan(_ code: String, title: String) -> ReferralPlan {
        return ReferralPlan(
            code: code,
            title: title,
            approved: false,
            revision: 0,
            ownerID: "",
            updatedAt: 0,
            graceDays: 0,
            status: ReferralPlanStatus.new
        )
    }
}
