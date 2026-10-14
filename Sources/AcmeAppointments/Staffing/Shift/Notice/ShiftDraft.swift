import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift draft is in its life cycle.
    enum ShiftDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A shift draft. Its code is unique within a tenant.
    final class ShiftDraft {
        var code: String
        var name: String
        var maximum: Double
        var capacity: Int
        var unit: String
        var segment: String
        var windowDays: Int
        var status: ShiftDraftStatus

        init(code: String, name: String, maximum: Double, capacity: Int, unit: String, segment: String, windowDays: Int, status: ShiftDraftStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.capacity = capacity
            self.unit = unit
            self.segment = segment
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ShiftDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ShiftDraftStatus.closed
            case .suspended:
                return next == ShiftDraftStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("shift draft") \(code)"
        }

        func netValue() -> Double {
            return (maximum * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> ShiftDraft {
            return ShiftDraft(
                code: code,
                name: name,
                maximum: maximum,
                capacity: capacity,
                unit: unit,
                segment: segment,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a shift draft in status draft.
    static func newShiftDraft(_ code: String, name: String) -> ShiftDraft {
        return ShiftDraft(
            code: code,
            name: name,
            maximum: 0.0,
            capacity: 0,
            unit: "",
            segment: "",
            windowDays: 0,
            status: ShiftDraftStatus.draft
        )
    }
}
