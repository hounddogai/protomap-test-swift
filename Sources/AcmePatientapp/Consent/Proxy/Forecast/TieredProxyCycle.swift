import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered proxy cycle is in its life cycle.
    enum TieredProxyCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered proxy cycle as the proxy team keeps it.
    final class TieredProxyCycle {
        var code: String
        var name: String
        var discount: Double
        var description: String
        var archived: Bool
        var visitMinutes: Int
        var status: TieredProxyCycleStatus

        init(code: String, name: String, discount: Double, description: String, archived: Bool, visitMinutes: Int, status: TieredProxyCycleStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.description = description
            self.archived = archived
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: TieredProxyCycleStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredProxyCycleStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredProxyCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredProxyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered proxy cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered proxy cycle") \(code)"
        }

        func netVolume() -> Double {
            return ((discount - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredProxyCycle {
            return TieredProxyCycle(
                code: code,
                name: name,
                discount: discount,
                description: description,
                archived: archived,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered proxy cycle in status requested.
    static func newTieredProxyCycle(_ code: String, name: String) -> TieredProxyCycle {
        return TieredProxyCycle(
            code: code,
            name: name,
            discount: 0.0,
            description: "",
            archived: false,
            visitMinutes: 0,
            status: TieredProxyCycleStatus.requested
        )
    }
}
