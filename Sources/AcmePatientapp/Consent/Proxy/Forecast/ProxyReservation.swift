import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy reservation is in its life cycle.
    enum ProxyReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A proxy reservation as the proxy team keeps it.
    final class ProxyReservation {
        var code: String
        var name: String
        var weight: Double
        var notes: String
        var cost: Double
        var phone: String
        var floorValue: Double
        var retries: Int
        var status: ProxyReservationStatus

        init(code: String, name: String, weight: Double, notes: String, cost: Double, phone: String, floorValue: Double, retries: Int, status: ProxyReservationStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.notes = notes
            self.cost = cost
            self.phone = phone
            self.floorValue = floorValue
            self.retries = retries
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

        func canMoveTo(_ next: ProxyReservationStatus) -> Bool {
            switch status {
            case .idle:
                return next == ProxyReservationStatus.draining || next == ProxyReservationStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ProxyReservationStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ProxyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return ((cost + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyReservation {
            return ProxyReservation(
                code: code,
                name: name,
                weight: weight,
                notes: notes,
                cost: cost,
                phone: phone,
                floorValue: floorValue,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy reservation in status idle.
    static func newProxyReservation(_ code: String, name: String) -> ProxyReservation {
        return ProxyReservation(
            code: code,
            name: name,
            weight: 0.0,
            notes: "",
            cost: 0.0,
            phone: "",
            floorValue: 0.0,
            retries: 0,
            status: ProxyReservationStatus.idle
        )
    }
}
