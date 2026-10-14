import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist slot is in its life cycle.
    enum WorklistSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One worklist slot, with what the planners need to act on it.
    final class WorklistSlot {
        var code: String
        var name: String
        var description: String
        var capacity: Int
        var cost: Double
        var weight: Double
        var label: String
        var windowDays: Int
        var status: WorklistSlotStatus

        init(code: String, name: String, description: String, capacity: Int, cost: Double, weight: Double, label: String, windowDays: Int, status: WorklistSlotStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.capacity = capacity
            self.cost = cost
            self.weight = weight
            self.label = label
            self.windowDays = windowDays
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

        func canMoveTo(_ next: WorklistSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == WorklistSlotStatus.validated
            case .validated:
                return next == WorklistSlotStatus.published || next == WorklistSlotStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WorklistSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return (weight * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> WorklistSlot {
            return WorklistSlot(
                code: code,
                name: name,
                description: description,
                capacity: capacity,
                cost: cost,
                weight: weight,
                label: label,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist slot in status created.
    static func newWorklistSlot(_ code: String, name: String) -> WorklistSlot {
        return WorklistSlot(
            code: code,
            name: name,
            description: "",
            capacity: 0,
            cost: 0.0,
            weight: 0.0,
            label: "",
            windowDays: 0,
            status: WorklistSlotStatus.created
        )
    }
}
