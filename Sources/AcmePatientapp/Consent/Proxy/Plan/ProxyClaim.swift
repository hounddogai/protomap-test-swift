import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy claim is in its life cycle.
    enum ProxyClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A proxy claim. Its code is unique within a tenant.
    final class ProxyClaim {
        var code: String
        var title: String
        var dosageMg: Double
        var procedureCode: String
        var updatedAt: Int
        var archived: Bool
        var status: ProxyClaimStatus

        init(code: String, title: String, dosageMg: Double, procedureCode: String, updatedAt: Int, archived: Bool, status: ProxyClaimStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.archived = archived
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

        func canMoveTo(_ next: ProxyClaimStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ProxyClaimStatus.revoked || next == ProxyClaimStatus.expired
            case .revoked:
                return next == ProxyClaimStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((dosageMg + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyClaim {
            return ProxyClaim(
                code: code,
                title: title,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                updatedAt: updatedAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy claim in status requested.
    static func newProxyClaim(_ code: String, title: String) -> ProxyClaim {
        return ProxyClaim(
            code: code,
            title: title,
            dosageMg: 0.0,
            procedureCode: "",
            updatedAt: 0,
            archived: false,
            status: ProxyClaimStatus.requested
        )
    }
}
