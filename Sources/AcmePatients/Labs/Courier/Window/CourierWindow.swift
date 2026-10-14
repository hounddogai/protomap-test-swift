import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier window is in its life cycle.
    enum CourierWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a courier window and its current status.
    final class CourierWindow {
        var code: String
        var title: String
        var revision: Int
        var durationMinutes: Int
        var floorValue: Double
        var status: CourierWindowStatus

        init(code: String, title: String, revision: Int, durationMinutes: Int, floorValue: Double, status: CourierWindowStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CourierWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == CourierWindowStatus.ready
            case .warming:
                return next == CourierWindowStatus.draining || next == CourierWindowStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: CourierWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("courier window") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(revision) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CourierWindow {
            return CourierWindow(
                code: code,
                title: title,
                revision: revision,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a courier window in status idle.
    static func newCourierWindow(_ code: String, title: String) -> CourierWindow {
        return CourierWindow(
            code: code,
            title: title,
            revision: 0,
            durationMinutes: 0,
            floorValue: 0.0,
            status: CourierWindowStatus.idle
        )
    }
}
