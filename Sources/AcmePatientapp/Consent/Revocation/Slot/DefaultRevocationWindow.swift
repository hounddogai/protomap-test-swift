import AcmePlatform
import Foundation

extension Consent {
    /// Where a default revocation window is in its life cycle.
    enum DefaultRevocationWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default revocation window, with what the planners need to act on it.
    final class DefaultRevocationWindow {
        var code: String
        var label: String
        var facility: String
        var cost: Double
        var limit: Int
        var maximum: Double
        var status: DefaultRevocationWindowStatus

        init(code: String, label: String, facility: String, cost: Double, limit: Int, maximum: Double, status: DefaultRevocationWindowStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.cost = cost
            self.limit = limit
            self.maximum = maximum
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

        func canMoveTo(_ next: DefaultRevocationWindowStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultRevocationWindowStatus.granted || next == DefaultRevocationWindowStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultRevocationWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRevocationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default revocation window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (cost * maximum * 100).rounded() / 100
        }

        func copyValue() -> DefaultRevocationWindow {
            return DefaultRevocationWindow(
                code: code,
                label: label,
                facility: facility,
                cost: cost,
                limit: limit,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default revocation window in status requested.
    static func newDefaultRevocationWindow(_ code: String, label: String) -> DefaultRevocationWindow {
        return DefaultRevocationWindow(
            code: code,
            label: label,
            facility: "",
            cost: 0.0,
            limit: 0,
            maximum: 0.0,
            status: DefaultRevocationWindowStatus.requested
        )
    }
}
