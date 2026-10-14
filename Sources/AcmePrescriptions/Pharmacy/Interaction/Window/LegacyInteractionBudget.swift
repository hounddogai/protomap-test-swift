import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy interaction budget is in its life cycle.
    enum LegacyInteractionBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One legacy interaction budget, with what the planners need to act on it.
    final class LegacyInteractionBudget {
        var code: String
        var name: String
        var budget: Double
        var capacity: Int
        var quantity: Int
        var facility: String
        var timezone: String
        var segment: String
        var phone: String
        var visitMinutes: Int
        var source: String
        var status: LegacyInteractionBudgetStatus

        init(code: String, name: String, budget: Double, capacity: Int, quantity: Int, facility: String, timezone: String, segment: String, phone: String, visitMinutes: Int, source: String, status: LegacyInteractionBudgetStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.capacity = capacity
            self.quantity = quantity
            self.facility = facility
            self.timezone = timezone
            self.segment = segment
            self.phone = phone
            self.visitMinutes = visitMinutes
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyInteractionBudgetStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyInteractionBudgetStatus.pending
            case .pending:
                return next == LegacyInteractionBudgetStatus.active || next == LegacyInteractionBudgetStatus.closed
            case .active:
                return next == LegacyInteractionBudgetStatus.suspended || next == LegacyInteractionBudgetStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyInteractionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy interaction budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return (Double(capacity) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInteractionBudget {
            return LegacyInteractionBudget(
                code: code,
                name: name,
                budget: budget,
                capacity: capacity,
                quantity: quantity,
                facility: facility,
                timezone: timezone,
                segment: segment,
                phone: phone,
                visitMinutes: visitMinutes,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy interaction budget in status draft.
    static func newLegacyInteractionBudget(_ code: String, name: String) -> LegacyInteractionBudget {
        return LegacyInteractionBudget(
            code: code,
            name: name,
            budget: 0.0,
            capacity: 0,
            quantity: 0,
            facility: "",
            timezone: "",
            segment: "",
            phone: "",
            visitMinutes: 0,
            source: "",
            status: LegacyInteractionBudgetStatus.draft
        )
    }
}
