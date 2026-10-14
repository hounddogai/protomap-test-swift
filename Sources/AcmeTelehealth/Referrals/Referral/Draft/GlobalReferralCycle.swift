import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global referral cycle is in its life cycle.
    enum GlobalReferralCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global referral cycle. Its code is unique within a tenant.
    final class GlobalReferralCycle {
        var code: String
        var title: String
        var endsAt: Int
        var durationMinutes: Int
        var patientRef: String
        var phone: String
        var status: GlobalReferralCycleStatus

        init(code: String, title: String, endsAt: Int, durationMinutes: Int, patientRef: String, phone: String, status: GlobalReferralCycleStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.phone = phone
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

        func canMoveTo(_ next: GlobalReferralCycleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalReferralCycleStatus.reopened || next == GlobalReferralCycleStatus.archived
            case .reopened:
                return next == GlobalReferralCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReferralCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global referral cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReferralCycle {
            return GlobalReferralCycle(
                code: code,
                title: title,
                endsAt: endsAt,
                durationMinutes: durationMinutes,
                patientRef: patientRef,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global referral cycle in status open.
    static func newGlobalReferralCycle(_ code: String, title: String) -> GlobalReferralCycle {
        return GlobalReferralCycle(
            code: code,
            title: title,
            endsAt: 0,
            durationMinutes: 0,
            patientRef: "",
            phone: "",
            status: GlobalReferralCycleStatus.`open`
        )
    }
}
