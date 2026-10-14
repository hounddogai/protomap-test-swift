import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation profile is in its life cycle.
    enum RevocationProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a revocation profile and its current status.
    final class RevocationProfile {
        var code: String
        var title: String
        var updatedAt: Int
        var pinned: Bool
        var notes: String
        var phone: String
        var status: RevocationProfileStatus

        init(code: String, title: String, updatedAt: Int, pinned: Bool, notes: String, phone: String, status: RevocationProfileStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.pinned = pinned
            self.notes = notes
            self.phone = phone
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

        func canMoveTo(_ next: RevocationProfileStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
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

        func moveTo(_ next: RevocationProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> RevocationProfile {
            return RevocationProfile(
                code: code,
                title: title,
                updatedAt: updatedAt,
                pinned: pinned,
                notes: notes,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation profile in status requested.
    static func newRevocationProfile(_ code: String, title: String) -> RevocationProfile {
        return RevocationProfile(
            code: code,
            title: title,
            updatedAt: 0,
            pinned: false,
            notes: "",
            phone: "",
            status: RevocationProfileStatus.requested
        )
    }
}
