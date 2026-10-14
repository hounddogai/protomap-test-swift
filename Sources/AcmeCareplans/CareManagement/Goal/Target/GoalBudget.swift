import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal budget is in its life cycle.
    enum GoalBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A goal budget. Its code is unique within a tenant.
    final class GoalBudget {
        var code: String
        var title: String
        var name: String
        var channel: String
        var contactEmail: String
        var label: String
        var phone: String
        var allergy: String
        var bed: String
        var quantity: Int
        var status: GoalBudgetStatus

        init(code: String, title: String, name: String, channel: String, contactEmail: String, label: String, phone: String, allergy: String, bed: String, quantity: Int, status: GoalBudgetStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.channel = channel
            self.contactEmail = contactEmail
            self.label = label
            self.phone = phone
            self.allergy = allergy
            self.bed = bed
            self.quantity = quantity
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

        func canMoveTo(_ next: GoalBudgetStatus) -> Bool {
            switch status {
            case .new:
                return next == GoalBudgetStatus.failed
            case .queued:
                return next == GoalBudgetStatus.running || next == GoalBudgetStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GoalBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> GoalBudget {
            return GoalBudget(
                code: code,
                title: title,
                name: name,
                channel: channel,
                contactEmail: contactEmail,
                label: label,
                phone: phone,
                allergy: allergy,
                bed: bed,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a goal budget in status new.
    static func newGoalBudget(_ code: String, title: String) -> GoalBudget {
        return GoalBudget(
            code: code,
            title: title,
            name: "",
            channel: "",
            contactEmail: "",
            label: "",
            phone: "",
            allergy: "",
            bed: "",
            quantity: 0,
            status: GoalBudgetStatus.new
        )
    }
}
