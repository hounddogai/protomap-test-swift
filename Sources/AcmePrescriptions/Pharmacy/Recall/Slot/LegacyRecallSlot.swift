import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy recall slot is in its life cycle.
    enum LegacyRecallSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One legacy recall slot, with what the planners need to act on it.
    final class LegacyRecallSlot {
        var code: String
        var name: String
        var specialty: String
        var budget: Double
        var segment: String
        var approved: Bool
        var status: LegacyRecallSlotStatus

        init(code: String, name: String, specialty: String, budget: Double, segment: String, approved: Bool, status: LegacyRecallSlotStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.budget = budget
            self.segment = segment
            self.approved = approved
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

        func canMoveTo(_ next: LegacyRecallSlotStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyRecallSlotStatus.completed || next == LegacyRecallSlotStatus.cancelled
            case .scheduled:
                return next == LegacyRecallSlotStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyRecallSlotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRecallSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy recall slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy recall slot") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> LegacyRecallSlot {
            return LegacyRecallSlot(
                code: code,
                name: name,
                specialty: specialty,
                budget: budget,
                segment: segment,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy recall slot in status planned.
    static func newLegacyRecallSlot(_ code: String, name: String) -> LegacyRecallSlot {
        return LegacyRecallSlot(
            code: code,
            name: name,
            specialty: "",
            budget: 0.0,
            segment: "",
            approved: false,
            status: LegacyRecallSlotStatus.planned
        )
    }
}
