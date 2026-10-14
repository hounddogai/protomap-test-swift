import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff plan is in its life cycle.
    enum HandoffPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a handoff plan and its current status.
    final class HandoffPlan {
        var code: String
        var name: String
        var ownerID: String
        var batchSize: Int
        var segment: String
        var minimum: Double
        var facility: String
        var durationMinutes: Int
        var capacity: Int
        var channel: String
        var pinned: Bool
        var status: HandoffPlanStatus

        init(code: String, name: String, ownerID: String, batchSize: Int, segment: String, minimum: Double, facility: String, durationMinutes: Int, capacity: Int, channel: String, pinned: Bool, status: HandoffPlanStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.segment = segment
            self.minimum = minimum
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.channel = channel
            self.pinned = pinned
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

        func canMoveTo(_ next: HandoffPlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == HandoffPlanStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == HandoffPlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((Double(capacity) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffPlan {
            return HandoffPlan(
                code: code,
                name: name,
                ownerID: ownerID,
                batchSize: batchSize,
                segment: segment,
                minimum: minimum,
                facility: facility,
                durationMinutes: durationMinutes,
                capacity: capacity,
                channel: channel,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a handoff plan in status planned.
    static func newHandoffPlan(_ code: String, name: String) -> HandoffPlan {
        return HandoffPlan(
            code: code,
            name: name,
            ownerID: "",
            batchSize: 0,
            segment: "",
            minimum: 0.0,
            facility: "",
            durationMinutes: 0,
            capacity: 0,
            channel: "",
            pinned: false,
            status: HandoffPlanStatus.planned
        )
    }
}
