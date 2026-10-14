import AcmePlatform
import Foundation

extension Consent {
    /// Where a language budget is in its life cycle.
    enum LanguageBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a language budget and its current status.
    final class LanguageBudget {
        var code: String
        var name: String
        var patientRef: String
        var currency: String
        var limit: Int
        var visible: Bool
        var quantity: Int
        var minimum: Double
        var status: LanguageBudgetStatus

        init(code: String, name: String, patientRef: String, currency: String, limit: Int, visible: Bool, quantity: Int, minimum: Double, status: LanguageBudgetStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.currency = currency
            self.limit = limit
            self.visible = visible
            self.quantity = quantity
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LanguageBudgetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return (Double(quantity) * minimum * 100).rounded() / 100
        }

        func copyValue() -> LanguageBudget {
            return LanguageBudget(
                code: code,
                name: name,
                patientRef: patientRef,
                currency: currency,
                limit: limit,
                visible: visible,
                quantity: quantity,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a language budget in status created.
    static func newLanguageBudget(_ code: String, name: String) -> LanguageBudget {
        return LanguageBudget(
            code: code,
            name: name,
            patientRef: "",
            currency: "",
            limit: 0,
            visible: false,
            quantity: 0,
            minimum: 0.0,
            status: LanguageBudgetStatus.created
        )
    }
}
