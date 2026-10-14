import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped referral allocation is in its life cycle.
    enum CappedReferralAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped referral allocation as the referral team keeps it.
    final class CappedReferralAllocation {
        var code: String
        var name: String
        var limit: Int
        var encounterID: String
        var attempts: Int
        var visitMinutes: Int
        var budget: Double
        var status: CappedReferralAllocationStatus

        init(code: String, name: String, limit: Int, encounterID: String, attempts: Int, visitMinutes: Int, budget: Double, status: CappedReferralAllocationStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.encounterID = encounterID
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.budget = budget
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

        func canMoveTo(_ next: CappedReferralAllocationStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedReferralAllocationStatus.active || next == CappedReferralAllocationStatus.closed
            case .pending:
                return next == CappedReferralAllocationStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedReferralAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped referral allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return (Double(visitMinutes) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> CappedReferralAllocation {
            return CappedReferralAllocation(
                code: code,
                name: name,
                limit: limit,
                encounterID: encounterID,
                attempts: attempts,
                visitMinutes: visitMinutes,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped referral allocation in status draft.
    static func newCappedReferralAllocation(_ code: String, name: String) -> CappedReferralAllocation {
        return CappedReferralAllocation(
            code: code,
            name: name,
            limit: 0,
            encounterID: "",
            attempts: 0,
            visitMinutes: 0,
            budget: 0.0,
            status: CappedReferralAllocationStatus.draft
        )
    }
}
