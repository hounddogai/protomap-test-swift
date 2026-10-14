import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral audit is in its life cycle.
    enum WeightedReferralAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted referral audit. Its code is unique within a tenant.
    final class WeightedReferralAudit {
        var code: String
        var name: String
        var rate: Double
        var copay: Double
        var payer: String
        var clinicianID: String
        var source: String
        var status: WeightedReferralAuditStatus

        init(code: String, name: String, rate: Double, copay: Double, payer: String, clinicianID: String, source: String, status: WeightedReferralAuditStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.copay = copay
            self.payer = payer
            self.clinicianID = clinicianID
            self.source = source
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

        func canMoveTo(_ next: WeightedReferralAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedReferralAuditStatus.approved || next == WeightedReferralAuditStatus.rejected
            case .approved:
                return next == WeightedReferralAuditStatus.withdrawn
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

        func moveTo(_ next: WeightedReferralAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted referral audit") \(code)"
        }

        func effectiveExposure() -> Double {
            return (copay * rate * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralAudit {
            return WeightedReferralAudit(
                code: code,
                name: name,
                rate: rate,
                copay: copay,
                payer: payer,
                clinicianID: clinicianID,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted referral audit in status proposed.
    static func newWeightedReferralAudit(_ code: String, name: String) -> WeightedReferralAudit {
        return WeightedReferralAudit(
            code: code,
            name: name,
            rate: 0.0,
            copay: 0.0,
            payer: "",
            clinicianID: "",
            source: "",
            status: WeightedReferralAuditStatus.proposed
        )
    }
}
