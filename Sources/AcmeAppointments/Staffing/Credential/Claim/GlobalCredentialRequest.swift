import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global credential request is in its life cycle.
    enum GlobalCredentialRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a global credential request and its current status.
    final class GlobalCredentialRequest {
        var code: String
        var title: String
        var ownerID: String
        var externalRef: String
        var payer: String
        var capacity: Int
        var dosageMg: Double
        var country: String
        var status: GlobalCredentialRequestStatus

        init(code: String, title: String, ownerID: String, externalRef: String, payer: String, capacity: Int, dosageMg: Double, country: String, status: GlobalCredentialRequestStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.externalRef = externalRef
            self.payer = payer
            self.capacity = capacity
            self.dosageMg = dosageMg
            self.country = country
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

        func canMoveTo(_ next: GlobalCredentialRequestStatus) -> Bool {
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
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == GlobalCredentialRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCredentialRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global credential request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((dosageMg + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCredentialRequest {
            return GlobalCredentialRequest(
                code: code,
                title: title,
                ownerID: ownerID,
                externalRef: externalRef,
                payer: payer,
                capacity: capacity,
                dosageMg: dosageMg,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global credential request in status proposed.
    static func newGlobalCredentialRequest(_ code: String, title: String) -> GlobalCredentialRequest {
        return GlobalCredentialRequest(
            code: code,
            title: title,
            ownerID: "",
            externalRef: "",
            payer: "",
            capacity: 0,
            dosageMg: 0.0,
            country: "",
            status: GlobalCredentialRequestStatus.proposed
        )
    }
}
