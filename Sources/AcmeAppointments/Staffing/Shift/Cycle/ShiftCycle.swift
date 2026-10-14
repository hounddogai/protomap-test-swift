import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift cycle is in its life cycle.
    enum ShiftCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A shift cycle. Its code is unique within a tenant.
    final class ShiftCycle {
        var code: String
        var name: String
        var reviewer: String
        var notes: String
        var cost: Double
        var timezone: String
        var copay: Double
        var status: ShiftCycleStatus

        init(code: String, name: String, reviewer: String, notes: String, cost: Double, timezone: String, copay: Double, status: ShiftCycleStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.notes = notes
            self.cost = cost
            self.timezone = timezone
            self.copay = copay
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

        func canMoveTo(_ next: ShiftCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == ShiftCycleStatus.completed || next == ShiftCycleStatus.cancelled
            case .scheduled:
                return next == ShiftCycleStatus.inProgress || next == ShiftCycleStatus.completed
            case .inProgress:
                return next == ShiftCycleStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ShiftCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((copay + cost) * 100).rounded() / 100
        }

        func copyValue() -> ShiftCycle {
            return ShiftCycle(
                code: code,
                name: name,
                reviewer: reviewer,
                notes: notes,
                cost: cost,
                timezone: timezone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift cycle in status planned.
    static func newShiftCycle(_ code: String, name: String) -> ShiftCycle {
        return ShiftCycle(
            code: code,
            name: name,
            reviewer: "",
            notes: "",
            cost: 0.0,
            timezone: "",
            copay: 0.0,
            status: ShiftCycleStatus.planned
        )
    }
}
