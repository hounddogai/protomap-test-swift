import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending network bundle is in its life cycle.
    enum PendingNetworkBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a pending network bundle and its current status.
    final class PendingNetworkBundle {
        var code: String
        var name: String
        var retries: Int
        var ward: String
        var unit: String
        var status: PendingNetworkBundleStatus

        init(code: String, name: String, retries: Int, ward: String, unit: String, status: PendingNetworkBundleStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.ward = ward
            self.unit = unit
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

        func canMoveTo(_ next: PendingNetworkBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PendingNetworkBundleStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> PendingNetworkBundle {
            return PendingNetworkBundle(
                code: code,
                name: name,
                retries: retries,
                ward: ward,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending network bundle in status proposed.
    static func newPendingNetworkBundle(_ code: String, name: String) -> PendingNetworkBundle {
        return PendingNetworkBundle(
            code: code,
            name: name,
            retries: 0,
            ward: "",
            unit: "",
            status: PendingNetworkBundleStatus.proposed
        )
    }
}
