import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential variance is in its life cycle.
    enum CredentialVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A credential variance. Its code is unique within a tenant.
    final class CredentialVariance {
        var code: String
        var label: String
        var quantity: Int
        var bed: String
        var copay: Double
        var status: CredentialVarianceStatus

        init(code: String, label: String, quantity: Int, bed: String, copay: Double, status: CredentialVarianceStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.bed = bed
            self.copay = copay
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

        func canMoveTo(_ next: CredentialVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CredentialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (copay * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CredentialVariance {
            return CredentialVariance(
                code: code,
                label: label,
                quantity: quantity,
                bed: bed,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a credential variance in status requested.
    static func newCredentialVariance(_ code: String, label: String) -> CredentialVariance {
        return CredentialVariance(
            code: code,
            label: label,
            quantity: 0,
            bed: "",
            copay: 0.0,
            status: CredentialVarianceStatus.requested
        )
    }
}
