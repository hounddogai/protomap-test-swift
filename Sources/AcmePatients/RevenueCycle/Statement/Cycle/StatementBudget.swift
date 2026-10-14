import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement budget is in its life cycle.
    enum StatementBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A statement budget as the statement team keeps it.
    final class StatementBudget {
        var code: String
        var title: String
        var payer: String
        var rate: Double
        var allergy: String
        var visible: Bool
        var floorValue: Double
        var status: StatementBudgetStatus

        init(code: String, title: String, payer: String, rate: Double, allergy: String, visible: Bool, floorValue: Double, status: StatementBudgetStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.rate = rate
            self.allergy = allergy
            self.visible = visible
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StatementBudgetStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StatementBudgetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return ((rate - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> StatementBudget {
            return StatementBudget(
                code: code,
                title: title,
                payer: payer,
                rate: rate,
                allergy: allergy,
                visible: visible,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement budget in status proposed.
    static func newStatementBudget(_ code: String, title: String) -> StatementBudget {
        return StatementBudget(
            code: code,
            title: title,
            payer: "",
            rate: 0.0,
            allergy: "",
            visible: false,
            floorValue: 0.0,
            status: StatementBudgetStatus.proposed
        )
    }
}
