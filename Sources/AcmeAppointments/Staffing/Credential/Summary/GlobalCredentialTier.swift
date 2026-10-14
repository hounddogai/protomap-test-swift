import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global credential tier is in its life cycle.
    enum GlobalCredentialTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global credential tier. Its code is unique within a tenant.
    final class GlobalCredentialTier {
        var code: String
        var label: String
        var cost: Double
        var discount: Double
        var patientRef: String
        var active: Bool
        var status: GlobalCredentialTierStatus

        init(code: String, label: String, cost: Double, discount: Double, patientRef: String, active: Bool, status: GlobalCredentialTierStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.discount = discount
            self.patientRef = patientRef
            self.active = active
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

        func canMoveTo(_ next: GlobalCredentialTierStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalCredentialTierStatus.revoked || next == GlobalCredentialTierStatus.expired
            case .revoked:
                return next == GlobalCredentialTierStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCredentialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global credential tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global credential tier") \(code)"
        }

        func adjustedTotal() -> Double {
            return (cost * discount * 100).rounded() / 100
        }

        func copyValue() -> GlobalCredentialTier {
            return GlobalCredentialTier(
                code: code,
                label: label,
                cost: cost,
                discount: discount,
                patientRef: patientRef,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global credential tier in status requested.
    static func newGlobalCredentialTier(_ code: String, label: String) -> GlobalCredentialTier {
        return GlobalCredentialTier(
            code: code,
            label: label,
            cost: 0.0,
            discount: 0.0,
            patientRef: "",
            active: false,
            status: GlobalCredentialTierStatus.requested
        )
    }
}
