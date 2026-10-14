import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary handoff cycle is in its life cycle.
    enum PrimaryHandoffCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary handoff cycle, with what the planners need to act on it.
    final class PrimaryHandoffCycle {
        var code: String
        var label: String
        var priority: Int
        var score: Double
        var ownerID: String
        var status: PrimaryHandoffCycleStatus

        init(code: String, label: String, priority: Int, score: Double, ownerID: String, status: PrimaryHandoffCycleStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.score = score
            self.ownerID = ownerID
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

        func canMoveTo(_ next: PrimaryHandoffCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryHandoffCycleStatus.warming || next == PrimaryHandoffCycleStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PrimaryHandoffCycleStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PrimaryHandoffCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary handoff cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((Double(priority) - score) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryHandoffCycle {
            return PrimaryHandoffCycle(
                code: code,
                label: label,
                priority: priority,
                score: score,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary handoff cycle in status idle.
    static func newPrimaryHandoffCycle(_ code: String, label: String) -> PrimaryHandoffCycle {
        return PrimaryHandoffCycle(
            code: code,
            label: label,
            priority: 0,
            score: 0.0,
            ownerID: "",
            status: PrimaryHandoffCycleStatus.idle
        )
    }
}
