import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped eligibility variance is in its life cycle.
    enum CappedEligibilityVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped eligibility variance. Its code is unique within a tenant.
    final class CappedEligibilityVariance {
        var code: String
        var name: String
        var copay: Double
        var refills: Int
        var ratio: Double
        var label: String
        var ceiling: Double
        var status: CappedEligibilityVarianceStatus

        init(code: String, name: String, copay: Double, refills: Int, ratio: Double, label: String, ceiling: Double, status: CappedEligibilityVarianceStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.refills = refills
            self.ratio = ratio
            self.label = label
            self.ceiling = ceiling
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

        func canMoveTo(_ next: CappedEligibilityVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CappedEligibilityVarianceStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedEligibilityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped eligibility variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((ratio - copay) * 100).rounded() / 100
        }

        func copyValue() -> CappedEligibilityVariance {
            return CappedEligibilityVariance(
                code: code,
                name: name,
                copay: copay,
                refills: refills,
                ratio: ratio,
                label: label,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped eligibility variance in status requested.
    static func newCappedEligibilityVariance(_ code: String, name: String) -> CappedEligibilityVariance {
        return CappedEligibilityVariance(
            code: code,
            name: name,
            copay: 0.0,
            refills: 0,
            ratio: 0.0,
            label: "",
            ceiling: 0.0,
            status: CappedEligibilityVarianceStatus.requested
        )
    }
}
