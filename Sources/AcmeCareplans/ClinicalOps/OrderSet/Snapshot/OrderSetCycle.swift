import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set cycle is in its life cycle.
    enum OrderSetCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a order set cycle and its current status.
    final class OrderSetCycle {
        var code: String
        var name: String
        var discount: Double
        var expiresAt: Int
        var maximum: Double
        var graceDays: Int
        var description: String
        var region: String
        var active: Bool
        var status: OrderSetCycleStatus

        init(code: String, name: String, discount: Double, expiresAt: Int, maximum: Double, graceDays: Int, description: String, region: String, active: Bool, status: OrderSetCycleStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.expiresAt = expiresAt
            self.maximum = maximum
            self.graceDays = graceDays
            self.description = description
            self.region = region
            self.active = active
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

        func canMoveTo(_ next: OrderSetCycleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OrderSetCycleStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OrderSetCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return ((discount - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetCycle {
            return OrderSetCycle(
                code: code,
                name: name,
                discount: discount,
                expiresAt: expiresAt,
                maximum: maximum,
                graceDays: graceDays,
                description: description,
                region: region,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a order set cycle in status proposed.
    static func newOrderSetCycle(_ code: String, name: String) -> OrderSetCycle {
        return OrderSetCycle(
            code: code,
            name: name,
            discount: 0.0,
            expiresAt: 0,
            maximum: 0.0,
            graceDays: 0,
            description: "",
            region: "",
            active: false,
            status: OrderSetCycleStatus.proposed
        )
    }
}
