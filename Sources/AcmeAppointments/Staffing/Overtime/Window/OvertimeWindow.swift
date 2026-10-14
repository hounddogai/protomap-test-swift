import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime window is in its life cycle.
    enum OvertimeWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A overtime window as the overtime team keeps it.
    final class OvertimeWindow {
        var code: String
        var title: String
        var description: String
        var threshold: Double
        var expiresAt: Int
        var status: OvertimeWindowStatus

        init(code: String, title: String, description: String, threshold: Double, expiresAt: Int, status: OvertimeWindowStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.threshold = threshold
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: OvertimeWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OvertimeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return (Double(expiresAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> OvertimeWindow {
            return OvertimeWindow(
                code: code,
                title: title,
                description: description,
                threshold: threshold,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime window in status idle.
    static func newOvertimeWindow(_ code: String, title: String) -> OvertimeWindow {
        return OvertimeWindow(
            code: code,
            title: title,
            description: "",
            threshold: 0.0,
            expiresAt: 0,
            status: OvertimeWindowStatus.idle
        )
    }
}
