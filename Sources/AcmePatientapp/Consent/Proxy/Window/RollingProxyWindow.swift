import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling proxy window is in its life cycle.
    enum RollingProxyWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling proxy window as the proxy team keeps it.
    final class RollingProxyWindow {
        var code: String
        var name: String
        var title: String
        var quantity: Int
        var floorValue: Double
        var amount: Double
        var status: RollingProxyWindowStatus

        init(code: String, name: String, title: String, quantity: Int, floorValue: Double, amount: Double, status: RollingProxyWindowStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.quantity = quantity
            self.floorValue = floorValue
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingProxyWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingProxyWindowStatus.warming || next == RollingProxyWindowStatus.ready
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingProxyWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingProxyWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling proxy window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return ((Double(quantity) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RollingProxyWindow {
            return RollingProxyWindow(
                code: code,
                name: name,
                title: title,
                quantity: quantity,
                floorValue: floorValue,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling proxy window in status idle.
    static func newRollingProxyWindow(_ code: String, name: String) -> RollingProxyWindow {
        return RollingProxyWindow(
            code: code,
            name: name,
            title: "",
            quantity: 0,
            floorValue: 0.0,
            amount: 0.0,
            status: RollingProxyWindowStatus.idle
        )
    }
}
