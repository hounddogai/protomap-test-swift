import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot milestone is in its life cycle.
    enum SlotMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One slot milestone, with what the planners need to act on it.
    final class SlotMilestone {
        var code: String
        var name: String
        var ratio: Double
        var minimum: Double
        var category: String
        var sequence: Int
        var status: SlotMilestoneStatus

        init(code: String, name: String, ratio: Double, minimum: Double, category: String, sequence: Int, status: SlotMilestoneStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.minimum = minimum
            self.category = category
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SlotMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return ((minimum + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SlotMilestone {
            return SlotMilestone(
                code: code,
                name: name,
                ratio: ratio,
                minimum: minimum,
                category: category,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a slot milestone in status open.
    static func newSlotMilestone(_ code: String, name: String) -> SlotMilestone {
        return SlotMilestone(
            code: code,
            name: name,
            ratio: 0.0,
            minimum: 0.0,
            category: "",
            sequence: 0,
            status: SlotMilestoneStatus.`open`
        )
    }
}
