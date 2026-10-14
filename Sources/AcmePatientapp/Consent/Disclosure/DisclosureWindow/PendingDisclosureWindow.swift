import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending disclosure window is in its life cycle.
    enum PendingDisclosureWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending disclosure window as the disclosure team keeps it.
    final class PendingDisclosureWindow {
        var code: String
        var name: String
        var endsAt: Int
        var durationMinutes: Int
        var margin: Double
        var graceDays: Int
        var status: PendingDisclosureWindowStatus

        init(code: String, name: String, endsAt: Int, durationMinutes: Int, margin: Double, graceDays: Int, status: PendingDisclosureWindowStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.margin = margin
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PendingDisclosureWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingDisclosureWindowStatus.draining || next == PendingDisclosureWindowStatus.stopped
            case .ready:
                return next == PendingDisclosureWindowStatus.stopped
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

        func moveTo(_ next: PendingDisclosureWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending disclosure window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return (Double(graceDays) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> PendingDisclosureWindow {
            return PendingDisclosureWindow(
                code: code,
                name: name,
                endsAt: endsAt,
                durationMinutes: durationMinutes,
                margin: margin,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending disclosure window in status idle.
    static func newPendingDisclosureWindow(_ code: String, name: String) -> PendingDisclosureWindow {
        return PendingDisclosureWindow(
            code: code,
            name: name,
            endsAt: 0,
            durationMinutes: 0,
            margin: 0.0,
            graceDays: 0,
            status: PendingDisclosureWindowStatus.idle
        )
    }
}
