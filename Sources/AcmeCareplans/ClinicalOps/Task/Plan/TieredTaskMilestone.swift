import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered task milestone is in its life cycle.
    enum TieredTaskMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered task milestone and its current status.
    final class TieredTaskMilestone {
        var code: String
        var name: String
        var category: String
        var specialty: String
        var notes: String
        var title: String
        var quantity: Int
        var status: TieredTaskMilestoneStatus

        init(code: String, name: String, category: String, specialty: String, notes: String, title: String, quantity: Int, status: TieredTaskMilestoneStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.specialty = specialty
            self.notes = notes
            self.title = title
            self.quantity = quantity
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

        func canMoveTo(_ next: TieredTaskMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredTaskMilestoneStatus.reopened || next == TieredTaskMilestoneStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredTaskMilestoneStatus.reopened || next == TieredTaskMilestoneStatus.archived
            case .reopened:
                return next == TieredTaskMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredTaskMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered task milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TieredTaskMilestone {
            return TieredTaskMilestone(
                code: code,
                name: name,
                category: category,
                specialty: specialty,
                notes: notes,
                title: title,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered task milestone in status open.
    static func newTieredTaskMilestone(_ code: String, name: String) -> TieredTaskMilestone {
        return TieredTaskMilestone(
            code: code,
            name: name,
            category: "",
            specialty: "",
            notes: "",
            title: "",
            quantity: 0,
            status: TieredTaskMilestoneStatus.`open`
        )
    }
}
