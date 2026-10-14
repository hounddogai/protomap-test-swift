import AcmePlatform
import Foundation

extension Labs {
    /// Where a result target is in its life cycle.
    enum ResultTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a result target and its current status.
    final class ResultTarget {
        var code: String
        var name: String
        var visible: Bool
        var summary: String
        var facility: String
        var notes: String
        var durationMinutes: Int
        var unit: String
        var minimum: Double
        var windowDays: Int
        var timezone: String
        var status: ResultTargetStatus

        init(code: String, name: String, visible: Bool, summary: String, facility: String, notes: String, durationMinutes: Int, unit: String, minimum: Double, windowDays: Int, timezone: String, status: ResultTargetStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.summary = summary
            self.facility = facility
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.minimum = minimum
            self.windowDays = windowDays
            self.timezone = timezone
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

        func canMoveTo(_ next: ResultTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == ResultTargetStatus.stopped
            case .warming:
                return next == ResultTargetStatus.ready || next == ResultTargetStatus.stopped
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

        func moveTo(_ next: ResultTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((Double(windowDays) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ResultTarget {
            return ResultTarget(
                code: code,
                name: name,
                visible: visible,
                summary: summary,
                facility: facility,
                notes: notes,
                durationMinutes: durationMinutes,
                unit: unit,
                minimum: minimum,
                windowDays: windowDays,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a result target in status idle.
    static func newResultTarget(_ code: String, name: String) -> ResultTarget {
        return ResultTarget(
            code: code,
            name: name,
            visible: false,
            summary: "",
            facility: "",
            notes: "",
            durationMinutes: 0,
            unit: "",
            minimum: 0.0,
            windowDays: 0,
            timezone: "",
            status: ResultTargetStatus.idle
        )
    }
}
