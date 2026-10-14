import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default referral agreement is in its life cycle.
    enum DefaultReferralAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default referral agreement. Its code is unique within a tenant.
    final class DefaultReferralAgreement {
        var code: String
        var name: String
        var timezone: String
        var summary: String
        var diagnosisCode: String
        var payer: String
        var score: Double
        var status: DefaultReferralAgreementStatus

        init(code: String, name: String, timezone: String, summary: String, diagnosisCode: String, payer: String, score: Double, status: DefaultReferralAgreementStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.payer = payer
            self.score = score
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

        func canMoveTo(_ next: DefaultReferralAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultReferralAgreementStatus.rejected || next == DefaultReferralAgreementStatus.withdrawn
            case .rejected:
                return next == DefaultReferralAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReferralAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default referral agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default referral agreement") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> DefaultReferralAgreement {
            return DefaultReferralAgreement(
                code: code,
                name: name,
                timezone: timezone,
                summary: summary,
                diagnosisCode: diagnosisCode,
                payer: payer,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default referral agreement in status proposed.
    static func newDefaultReferralAgreement(_ code: String, name: String) -> DefaultReferralAgreement {
        return DefaultReferralAgreement(
            code: code,
            name: name,
            timezone: "",
            summary: "",
            diagnosisCode: "",
            payer: "",
            score: 0.0,
            status: DefaultReferralAgreementStatus.proposed
        )
    }
}
