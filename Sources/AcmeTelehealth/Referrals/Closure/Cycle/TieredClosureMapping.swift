import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered closure mapping is in its life cycle.
    enum TieredClosureMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered closure mapping, with what the planners need to act on it.
    final class TieredClosureMapping {
        var code: String
        var title: String
        var capacity: Int
        var discount: Double
        var externalRef: String
        var status: TieredClosureMappingStatus

        init(code: String, title: String, capacity: Int, discount: Double, externalRef: String, status: TieredClosureMappingStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.discount = discount
            self.externalRef = externalRef
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

        func canMoveTo(_ next: TieredClosureMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredClosureMappingStatus.revoked
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

        func moveTo(_ next: TieredClosureMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered closure mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((Double(capacity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> TieredClosureMapping {
            return TieredClosureMapping(
                code: code,
                title: title,
                capacity: capacity,
                discount: discount,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered closure mapping in status requested.
    static func newTieredClosureMapping(_ code: String, title: String) -> TieredClosureMapping {
        return TieredClosureMapping(
            code: code,
            title: title,
            capacity: 0,
            discount: 0.0,
            externalRef: "",
            status: TieredClosureMappingStatus.requested
        )
    }
}
