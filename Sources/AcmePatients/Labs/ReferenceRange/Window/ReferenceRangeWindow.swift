import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range window is in its life cycle.
    enum ReferenceRangeWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a reference range window and its current status.
    final class ReferenceRangeWindow {
        var code: String
        var title: String
        var priority: Int
        var notes: String
        var procedureCode: String
        var durationMinutes: Int
        var windowDays: Int
        var capacity: Int
        var unit: String
        var status: ReferenceRangeWindowStatus

        init(code: String, title: String, priority: Int, notes: String, procedureCode: String, durationMinutes: Int, windowDays: Int, capacity: Int, unit: String, status: ReferenceRangeWindowStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.notes = notes
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.capacity = capacity
            self.unit = unit
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

        func canMoveTo(_ next: ReferenceRangeWindowStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReferenceRangeWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("reference range window") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(capacity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeWindow {
            return ReferenceRangeWindow(
                code: code,
                title: title,
                priority: priority,
                notes: notes,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                capacity: capacity,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a reference range window in status requested.
    static func newReferenceRangeWindow(_ code: String, title: String) -> ReferenceRangeWindow {
        return ReferenceRangeWindow(
            code: code,
            title: title,
            priority: 0,
            notes: "",
            procedureCode: "",
            durationMinutes: 0,
            windowDays: 0,
            capacity: 0,
            unit: "",
            status: ReferenceRangeWindowStatus.requested
        )
    }
}
