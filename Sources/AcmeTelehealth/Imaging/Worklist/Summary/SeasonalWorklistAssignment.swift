import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal worklist assignment is in its life cycle.
    enum SeasonalWorklistAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One seasonal worklist assignment, with what the planners need to act on it.
    final class SeasonalWorklistAssignment {
        var code: String
        var label: String
        var pinned: Bool
        var bed: String
        var quantity: Int
        var status: SeasonalWorklistAssignmentStatus

        init(code: String, label: String, pinned: Bool, bed: String, quantity: Int, status: SeasonalWorklistAssignmentStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.bed = bed
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalWorklistAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalWorklistAssignmentStatus.validated || next == SeasonalWorklistAssignmentStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == SeasonalWorklistAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalWorklistAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal worklist assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SeasonalWorklistAssignment {
            return SeasonalWorklistAssignment(
                code: code,
                label: label,
                pinned: pinned,
                bed: bed,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal worklist assignment in status created.
    static func newSeasonalWorklistAssignment(_ code: String, label: String) -> SeasonalWorklistAssignment {
        return SeasonalWorklistAssignment(
            code: code,
            label: label,
            pinned: false,
            bed: "",
            quantity: 0,
            status: SeasonalWorklistAssignmentStatus.created
        )
    }
}
