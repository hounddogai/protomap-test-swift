import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional disclosure window is in its life cycle.
    enum RegionalDisclosureWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional disclosure window. Its code is unique within a tenant.
    final class RegionalDisclosureWindow {
        var code: String
        var title: String
        var channel: String
        var graceDays: Int
        var rate: Double
        var status: RegionalDisclosureWindowStatus

        init(code: String, title: String, channel: String, graceDays: Int, rate: Double, status: RegionalDisclosureWindowStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.graceDays = graceDays
            self.rate = rate
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

        func canMoveTo(_ next: RegionalDisclosureWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalDisclosureWindowStatus.inProgress || next == RegionalDisclosureWindowStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalDisclosureWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalDisclosureWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional disclosure window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((Double(graceDays) + rate) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDisclosureWindow {
            return RegionalDisclosureWindow(
                code: code,
                title: title,
                channel: channel,
                graceDays: graceDays,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional disclosure window in status planned.
    static func newRegionalDisclosureWindow(_ code: String, title: String) -> RegionalDisclosureWindow {
        return RegionalDisclosureWindow(
            code: code,
            title: title,
            channel: "",
            graceDays: 0,
            rate: 0.0,
            status: RegionalDisclosureWindowStatus.planned
        )
    }
}
