import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift budget is in its life cycle.
    enum ShiftBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One shift budget, with what the planners need to act on it.
    final class ShiftBudget {
        var code: String
        var title: String
        var attributes: [String: String]
        var quantity: Int
        var payer: String
        var status: ShiftBudgetStatus

        init(code: String, title: String, attributes: [String: String], quantity: Int, payer: String, status: ShiftBudgetStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.quantity = quantity
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == ShiftBudgetStatus.granted || next == ShiftBudgetStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ShiftBudgetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ShiftBudget {
            return ShiftBudget(
                code: code,
                title: title,
                attributes: attributes,
                quantity: quantity,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a shift budget in status requested.
    static func newShiftBudget(_ code: String, title: String) -> ShiftBudget {
        return ShiftBudget(
            code: code,
            title: title,
            attributes: [:],
            quantity: 0,
            payer: "",
            status: ShiftBudgetStatus.requested
        )
    }
}
