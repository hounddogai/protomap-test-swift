import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback float pool milestone is in its life cycle.
    enum FallbackFloatPoolMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback float pool milestone and its current status.
    final class FallbackFloatPoolMilestone {
        var code: String
        var name: String
        var visible: Bool
        var reviewer: String
        var contactEmail: String
        var ceiling: Double
        var priority: Int
        var notes: String
        var status: FallbackFloatPoolMilestoneStatus

        init(code: String, name: String, visible: Bool, reviewer: String, contactEmail: String, ceiling: Double, priority: Int, notes: String, status: FallbackFloatPoolMilestoneStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.reviewer = reviewer
            self.contactEmail = contactEmail
            self.ceiling = ceiling
            self.priority = priority
            self.notes = notes
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

        func canMoveTo(_ next: FallbackFloatPoolMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackFloatPoolMilestoneStatus.ready || next == FallbackFloatPoolMilestoneStatus.stopped
            case .warming:
                return next == FallbackFloatPoolMilestoneStatus.ready || next == FallbackFloatPoolMilestoneStatus.stopped
            case .ready:
                return next == FallbackFloatPoolMilestoneStatus.draining || next == FallbackFloatPoolMilestoneStatus.stopped
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

        func moveTo(_ next: FallbackFloatPoolMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback float pool milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return ((Double(priority) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFloatPoolMilestone {
            return FallbackFloatPoolMilestone(
                code: code,
                name: name,
                visible: visible,
                reviewer: reviewer,
                contactEmail: contactEmail,
                ceiling: ceiling,
                priority: priority,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback float pool milestone in status idle.
    static func newFallbackFloatPoolMilestone(_ code: String, name: String) -> FallbackFloatPoolMilestone {
        return FallbackFloatPoolMilestone(
            code: code,
            name: name,
            visible: false,
            reviewer: "",
            contactEmail: "",
            ceiling: 0.0,
            priority: 0,
            notes: "",
            status: FallbackFloatPoolMilestoneStatus.idle
        )
    }
}
