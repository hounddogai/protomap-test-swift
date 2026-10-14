import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary referral threshold is in its life cycle.
    enum PrimaryReferralThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary referral threshold. Its code is unique within a tenant.
    final class PrimaryReferralThreshold {
        var code: String
        var label: String
        var active: Bool
        var copay: Double
        var pinned: Bool
        var status: PrimaryReferralThresholdStatus

        init(code: String, label: String, active: Bool, copay: Double, pinned: Bool, status: PrimaryReferralThresholdStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.copay = copay
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryReferralThresholdStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PrimaryReferralThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary referral threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary referral threshold") \(code)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> PrimaryReferralThreshold {
            return PrimaryReferralThreshold(
                code: code,
                label: label,
                active: active,
                copay: copay,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary referral threshold in status created.
    static func newPrimaryReferralThreshold(_ code: String, label: String) -> PrimaryReferralThreshold {
        return PrimaryReferralThreshold(
            code: code,
            label: label,
            active: false,
            copay: 0.0,
            pinned: false,
            status: PrimaryReferralThresholdStatus.created
        )
    }
}
