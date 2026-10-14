import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global transfer assignment is in its life cycle.
    enum GlobalTransferAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global transfer assignment, with what the planners need to act on it.
    final class GlobalTransferAssignment {
        var code: String
        var name: String
        var capacity: Int
        var patientRef: String
        var unit: String
        var minimum: Double
        var status: GlobalTransferAssignmentStatus

        init(code: String, name: String, capacity: Int, patientRef: String, unit: String, minimum: Double, status: GlobalTransferAssignmentStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.patientRef = patientRef
            self.unit = unit
            self.minimum = minimum
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

        func canMoveTo(_ next: GlobalTransferAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalTransferAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global transfer assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalTransferAssignment {
            return GlobalTransferAssignment(
                code: code,
                name: name,
                capacity: capacity,
                patientRef: patientRef,
                unit: unit,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global transfer assignment in status new.
    static func newGlobalTransferAssignment(_ code: String, name: String) -> GlobalTransferAssignment {
        return GlobalTransferAssignment(
            code: code,
            name: name,
            capacity: 0,
            patientRef: "",
            unit: "",
            minimum: 0.0,
            status: GlobalTransferAssignmentStatus.new
        )
    }
}
