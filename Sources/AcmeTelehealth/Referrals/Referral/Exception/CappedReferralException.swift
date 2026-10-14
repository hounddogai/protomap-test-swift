import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped referral exception is in its life cycle.
    enum CappedReferralExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped referral exception. Its code is unique within a tenant.
    final class CappedReferralException {
        var code: String
        var name: String
        var reviewer: String
        var budget: Double
        var visitMinutes: Int
        var retries: Int
        var dosageMg: Double
        var ceiling: Double
        var acuity: Int
        var maximum: Double
        var status: CappedReferralExceptionStatus

        init(code: String, name: String, reviewer: String, budget: Double, visitMinutes: Int, retries: Int, dosageMg: Double, ceiling: Double, acuity: Int, maximum: Double, status: CappedReferralExceptionStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.retries = retries
            self.dosageMg = dosageMg
            self.ceiling = ceiling
            self.acuity = acuity
            self.maximum = maximum
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

        func canMoveTo(_ next: CappedReferralExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CappedReferralExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped referral exception") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(retries) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> CappedReferralException {
            return CappedReferralException(
                code: code,
                name: name,
                reviewer: reviewer,
                budget: budget,
                visitMinutes: visitMinutes,
                retries: retries,
                dosageMg: dosageMg,
                ceiling: ceiling,
                acuity: acuity,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped referral exception in status proposed.
    static func newCappedReferralException(_ code: String, name: String) -> CappedReferralException {
        return CappedReferralException(
            code: code,
            name: name,
            reviewer: "",
            budget: 0.0,
            visitMinutes: 0,
            retries: 0,
            dosageMg: 0.0,
            ceiling: 0.0,
            acuity: 0,
            maximum: 0.0,
            status: CappedReferralExceptionStatus.proposed
        )
    }
}
