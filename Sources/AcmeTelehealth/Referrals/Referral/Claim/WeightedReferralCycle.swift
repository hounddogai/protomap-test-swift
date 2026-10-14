import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral cycle is in its life cycle.
    enum WeightedReferralCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a weighted referral cycle and its current status.
    final class WeightedReferralCycle {
        var code: String
        var title: String
        var unit: String
        var payer: String
        var reviewer: String
        var expiresAt: Int
        var source: String
        var status: WeightedReferralCycleStatus

        init(code: String, title: String, unit: String, payer: String, reviewer: String, expiresAt: Int, source: String, status: WeightedReferralCycleStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.payer = payer
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedReferralCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedReferralCycleStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedReferralCycleStatus.suspended || next == WeightedReferralCycleStatus.closed
            case .suspended:
                return next == WeightedReferralCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedReferralCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> WeightedReferralCycle {
            return WeightedReferralCycle(
                code: code,
                title: title,
                unit: unit,
                payer: payer,
                reviewer: reviewer,
                expiresAt: expiresAt,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted referral cycle in status draft.
    static func newWeightedReferralCycle(_ code: String, title: String) -> WeightedReferralCycle {
        return WeightedReferralCycle(
            code: code,
            title: title,
            unit: "",
            payer: "",
            reviewer: "",
            expiresAt: 0,
            source: "",
            status: WeightedReferralCycleStatus.draft
        )
    }
}
