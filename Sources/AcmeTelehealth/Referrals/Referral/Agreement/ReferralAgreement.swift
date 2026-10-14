import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral agreement is in its life cycle.
    enum ReferralAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A referral agreement as the referral team keeps it.
    final class ReferralAgreement {
        var code: String
        var label: String
        var floorValue: Double
        var country: String
        var threshold: Double
        var status: ReferralAgreementStatus

        init(code: String, label: String, floorValue: Double, country: String, threshold: Double, status: ReferralAgreementStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.country = country
            self.threshold = threshold
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

        func canMoveTo(_ next: ReferralAgreementStatus) -> Bool {
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
                return next == ReferralAgreementStatus.running || next == ReferralAgreementStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ReferralAgreementStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((threshold + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ReferralAgreement {
            return ReferralAgreement(
                code: code,
                label: label,
                floorValue: floorValue,
                country: country,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a referral agreement in status new.
    static func newReferralAgreement(_ code: String, label: String) -> ReferralAgreement {
        return ReferralAgreement(
            code: code,
            label: label,
            floorValue: 0.0,
            country: "",
            threshold: 0.0,
            status: ReferralAgreementStatus.new
        )
    }
}
