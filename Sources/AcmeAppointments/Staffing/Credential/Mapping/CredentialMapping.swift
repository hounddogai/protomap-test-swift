import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential mapping is in its life cycle.
    enum CredentialMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One credential mapping, with what the planners need to act on it.
    final class CredentialMapping {
        var code: String
        var name: String
        var discount: Double
        var quantity: Int
        var retries: Int
        var copay: Double
        var rate: Double
        var segment: String
        var patientRef: String
        var status: CredentialMappingStatus

        init(code: String, name: String, discount: Double, quantity: Int, retries: Int, copay: Double, rate: Double, segment: String, patientRef: String, status: CredentialMappingStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.quantity = quantity
            self.retries = retries
            self.copay = copay
            self.rate = rate
            self.segment = segment
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CredentialMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == CredentialMappingStatus.revoked
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

        func moveTo(_ next: CredentialMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential mapping") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(retries) * copay * 100).rounded() / 100
        }

        func copyValue() -> CredentialMapping {
            return CredentialMapping(
                code: code,
                name: name,
                discount: discount,
                quantity: quantity,
                retries: retries,
                copay: copay,
                rate: rate,
                segment: segment,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a credential mapping in status requested.
    static func newCredentialMapping(_ code: String, name: String) -> CredentialMapping {
        return CredentialMapping(
            code: code,
            name: name,
            discount: 0.0,
            quantity: 0,
            retries: 0,
            copay: 0.0,
            rate: 0.0,
            segment: "",
            patientRef: "",
            status: CredentialMappingStatus.requested
        )
    }
}
