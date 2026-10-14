import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy window is in its life cycle.
    enum ProxyWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A proxy window as the proxy team keeps it.
    final class ProxyWindow {
        var code: String
        var label: String
        var facility: String
        var rate: Double
        var limit: Int
        var endsAt: Int
        var refills: Int
        var locale: String
        var status: ProxyWindowStatus

        init(code: String, label: String, facility: String, rate: Double, limit: Int, endsAt: Int, refills: Int, locale: String, status: ProxyWindowStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.rate = rate
            self.limit = limit
            self.endsAt = endsAt
            self.refills = refills
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ProxyWindowStatus.inProgress || next == ProxyWindowStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ProxyWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("proxy window") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(refills) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyWindow {
            return ProxyWindow(
                code: code,
                label: label,
                facility: facility,
                rate: rate,
                limit: limit,
                endsAt: endsAt,
                refills: refills,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy window in status planned.
    static func newProxyWindow(_ code: String, label: String) -> ProxyWindow {
        return ProxyWindow(
            code: code,
            label: label,
            facility: "",
            rate: 0.0,
            limit: 0,
            endsAt: 0,
            refills: 0,
            locale: "",
            status: ProxyWindowStatus.planned
        )
    }
}
