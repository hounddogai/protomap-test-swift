import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled referral mapping is in its life cycle.
    enum ScheduledReferralMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled referral mapping as the referral team keeps it.
    final class ScheduledReferralMapping {
        var code: String
        var title: String
        var summary: String
        var payer: String
        var bed: String
        var acuity: Int
        var amount: Double
        var status: ScheduledReferralMappingStatus

        init(code: String, title: String, summary: String, payer: String, bed: String, acuity: Int, amount: Double, status: ScheduledReferralMappingStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.payer = payer
            self.bed = bed
            self.acuity = acuity
            self.amount = amount
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

        func canMoveTo(_ next: ScheduledReferralMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledReferralMappingStatus.inProgress || next == ScheduledReferralMappingStatus.completed
            case .scheduled:
                return next == ScheduledReferralMappingStatus.inProgress || next == ScheduledReferralMappingStatus.cancelled
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

        func moveTo(_ next: ScheduledReferralMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled referral mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((Double(acuity) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReferralMapping {
            return ScheduledReferralMapping(
                code: code,
                title: title,
                summary: summary,
                payer: payer,
                bed: bed,
                acuity: acuity,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled referral mapping in status planned.
    static func newScheduledReferralMapping(_ code: String, title: String) -> ScheduledReferralMapping {
        return ScheduledReferralMapping(
            code: code,
            title: title,
            summary: "",
            payer: "",
            bed: "",
            acuity: 0,
            amount: 0.0,
            status: ScheduledReferralMappingStatus.planned
        )
    }
}
