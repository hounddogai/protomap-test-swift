import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense window is in its life cycle.
    enum DispenseWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One dispense window, with what the planners need to act on it.
    final class DispenseWindow {
        var code: String
        var name: String
        var floorValue: Double
        var active: Bool
        var attempts: Int
        var segment: String
        var score: Double
        var notes: String
        var status: DispenseWindowStatus

        init(code: String, name: String, floorValue: Double, active: Bool, attempts: Int, segment: String, score: Double, notes: String, status: DispenseWindowStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.active = active
            self.attempts = attempts
            self.segment = segment
            self.score = score
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == DispenseWindowStatus.active || next == DispenseWindowStatus.suspended
            case .pending:
                return next == DispenseWindowStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DispenseWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return ((floorValue + score) * 100).rounded() / 100
        }

        func copyValue() -> DispenseWindow {
            return DispenseWindow(
                code: code,
                name: name,
                floorValue: floorValue,
                active: active,
                attempts: attempts,
                segment: segment,
                score: score,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a dispense window in status draft.
    static func newDispenseWindow(_ code: String, name: String) -> DispenseWindow {
        return DispenseWindow(
            code: code,
            name: name,
            floorValue: 0.0,
            active: false,
            attempts: 0,
            segment: "",
            score: 0.0,
            notes: "",
            status: DispenseWindowStatus.draft
        )
    }
}
