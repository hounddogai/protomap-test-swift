import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral digest is in its life cycle.
    enum ReferralDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A referral digest as the referral team keeps it.
    final class ReferralDigest {
        var code: String
        var label: String
        var dosageMg: Double
        var rate: Double
        var ceiling: Double
        var externalRef: String
        var status: ReferralDigestStatus

        init(code: String, label: String, dosageMg: Double, rate: Double, ceiling: Double, externalRef: String, status: ReferralDigestStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.rate = rate
            self.ceiling = ceiling
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReferralDigestStatus.revoked || next == ReferralDigestStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReferralDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("referral digest") \(code)"
        }

        func netExposure() -> Double {
            return ((rate - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ReferralDigest {
            return ReferralDigest(
                code: code,
                label: label,
                dosageMg: dosageMg,
                rate: rate,
                ceiling: ceiling,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a referral digest in status requested.
    static func newReferralDigest(_ code: String, label: String) -> ReferralDigest {
        return ReferralDigest(
            code: code,
            label: label,
            dosageMg: 0.0,
            rate: 0.0,
            ceiling: 0.0,
            externalRef: "",
            status: ReferralDigestStatus.requested
        )
    }
}
