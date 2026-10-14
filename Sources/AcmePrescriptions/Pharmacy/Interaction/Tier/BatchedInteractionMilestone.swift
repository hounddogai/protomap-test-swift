import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched interaction milestone is in its life cycle.
    enum BatchedInteractionMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched interaction milestone and its current status.
    final class BatchedInteractionMilestone {
        var code: String
        var name: String
        var floorValue: Double
        var sequence: Int
        var unit: String
        var pinned: Bool
        var weight: Double
        var durationMinutes: Int
        var status: BatchedInteractionMilestoneStatus

        init(code: String, name: String, floorValue: Double, sequence: Int, unit: String, pinned: Bool, weight: Double, durationMinutes: Int, status: BatchedInteractionMilestoneStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.sequence = sequence
            self.unit = unit
            self.pinned = pinned
            self.weight = weight
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: BatchedInteractionMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedInteractionMilestoneStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedInteractionMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedInteractionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched interaction milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> BatchedInteractionMilestone {
            return BatchedInteractionMilestone(
                code: code,
                name: name,
                floorValue: floorValue,
                sequence: sequence,
                unit: unit,
                pinned: pinned,
                weight: weight,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched interaction milestone in status idle.
    static func newBatchedInteractionMilestone(_ code: String, name: String) -> BatchedInteractionMilestone {
        return BatchedInteractionMilestone(
            code: code,
            name: name,
            floorValue: 0.0,
            sequence: 0,
            unit: "",
            pinned: false,
            weight: 0.0,
            durationMinutes: 0,
            status: BatchedInteractionMilestoneStatus.idle
        )
    }
}
