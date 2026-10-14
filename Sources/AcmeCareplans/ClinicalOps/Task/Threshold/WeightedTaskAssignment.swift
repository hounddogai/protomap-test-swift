import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted task assignment is in its life cycle.
    enum WeightedTaskAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted task assignment as the task team keeps it.
    final class WeightedTaskAssignment {
        var code: String
        var label: String
        var checksum: String
        var discount: Double
        var capacity: Int
        var encounterID: String
        var score: Double
        var status: WeightedTaskAssignmentStatus

        init(code: String, label: String, checksum: String, discount: Double, capacity: Int, encounterID: String, score: Double, status: WeightedTaskAssignmentStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.discount = discount
            self.capacity = capacity
            self.encounterID = encounterID
            self.score = score
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

        func canMoveTo(_ next: WeightedTaskAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedTaskAssignmentStatus.draining || next == WeightedTaskAssignmentStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WeightedTaskAssignmentStatus.draining
            case .draining:
                return next == WeightedTaskAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTaskAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted task assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return (discount * score * 100).rounded() / 100
        }

        func copyValue() -> WeightedTaskAssignment {
            return WeightedTaskAssignment(
                code: code,
                label: label,
                checksum: checksum,
                discount: discount,
                capacity: capacity,
                encounterID: encounterID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted task assignment in status idle.
    static func newWeightedTaskAssignment(_ code: String, label: String) -> WeightedTaskAssignment {
        return WeightedTaskAssignment(
            code: code,
            label: label,
            checksum: "",
            discount: 0.0,
            capacity: 0,
            encounterID: "",
            score: 0.0,
            status: WeightedTaskAssignmentStatus.idle
        )
    }
}
