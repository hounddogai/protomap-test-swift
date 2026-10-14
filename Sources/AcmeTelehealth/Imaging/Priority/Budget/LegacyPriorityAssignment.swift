import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy priority assignment is in its life cycle.
    enum LegacyPriorityAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a legacy priority assignment and its current status.
    final class LegacyPriorityAssignment {
        var code: String
        var name: String
        var unit: String
        var discount: Double
        var pinned: Bool
        var archived: Bool
        var durationMinutes: Int
        var graceDays: Int
        var status: LegacyPriorityAssignmentStatus

        init(code: String, name: String, unit: String, discount: Double, pinned: Bool, archived: Bool, durationMinutes: Int, graceDays: Int, status: LegacyPriorityAssignmentStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.discount = discount
            self.pinned = pinned
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyPriorityAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyPriorityAssignmentStatus.done || next == LegacyPriorityAssignmentStatus.failed
            case .queued:
                return next == LegacyPriorityAssignmentStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LegacyPriorityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy priority assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy priority assignment") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((discount - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyPriorityAssignment {
            return LegacyPriorityAssignment(
                code: code,
                name: name,
                unit: unit,
                discount: discount,
                pinned: pinned,
                archived: archived,
                durationMinutes: durationMinutes,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy priority assignment in status new.
    static func newLegacyPriorityAssignment(_ code: String, name: String) -> LegacyPriorityAssignment {
        return LegacyPriorityAssignment(
            code: code,
            name: name,
            unit: "",
            discount: 0.0,
            pinned: false,
            archived: false,
            durationMinutes: 0,
            graceDays: 0,
            status: LegacyPriorityAssignmentStatus.new
        )
    }
}
