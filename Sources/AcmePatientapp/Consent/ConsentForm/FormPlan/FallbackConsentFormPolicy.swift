import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback consent form policy is in its life cycle.
    enum FallbackConsentFormPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback consent form policy as the consent form team keeps it.
    final class FallbackConsentFormPolicy {
        var code: String
        var label: String
        var currency: String
        var pinned: Bool
        var floorValue: Double
        var status: FallbackConsentFormPolicyStatus

        init(code: String, label: String, currency: String, pinned: Bool, floorValue: Double, status: FallbackConsentFormPolicyStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.pinned = pinned
            self.floorValue = floorValue
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

        func canMoveTo(_ next: FallbackConsentFormPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackConsentFormPolicyStatus.rejected
            case .approved:
                return next == FallbackConsentFormPolicyStatus.rejected || next == FallbackConsentFormPolicyStatus.withdrawn
            case .rejected:
                return next == FallbackConsentFormPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackConsentFormPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback consent form policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> FallbackConsentFormPolicy {
            return FallbackConsentFormPolicy(
                code: code,
                label: label,
                currency: currency,
                pinned: pinned,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback consent form policy in status proposed.
    static func newFallbackConsentFormPolicy(_ code: String, label: String) -> FallbackConsentFormPolicy {
        return FallbackConsentFormPolicy(
            code: code,
            label: label,
            currency: "",
            pinned: false,
            floorValue: 0.0,
            status: FallbackConsentFormPolicyStatus.proposed
        )
    }
}
