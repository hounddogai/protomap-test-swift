import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential target is in its life cycle.
    enum CredentialTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a credential target and its current status.
    final class CredentialTarget {
        var code: String
        var title: String
        var ownerID: String
        var checksum: String
        var source: String
        var amount: Double
        var status: CredentialTargetStatus

        init(code: String, title: String, ownerID: String, checksum: String, source: String, amount: Double, status: CredentialTargetStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.checksum = checksum
            self.source = source
            self.amount = amount
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

        func canMoveTo(_ next: CredentialTargetStatus) -> Bool {
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
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CredentialTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CredentialTarget {
            return CredentialTarget(
                code: code,
                title: title,
                ownerID: ownerID,
                checksum: checksum,
                source: source,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a credential target in status requested.
    static func newCredentialTarget(_ code: String, title: String) -> CredentialTarget {
        return CredentialTarget(
            code: code,
            title: title,
            ownerID: "",
            checksum: "",
            source: "",
            amount: 0.0,
            status: CredentialTargetStatus.requested
        )
    }
}
