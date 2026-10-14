import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution budget is in its life cycle.
    enum SubstitutionBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A substitution budget as the substitution team keeps it.
    final class SubstitutionBudget {
        var code: String
        var title: String
        var clinicianID: String
        var quantity: Int
        var name: String
        var reviewer: String
        var acuity: Int
        var updatedAt: Int
        var cost: Double
        var sequence: Int
        var status: SubstitutionBudgetStatus

        init(code: String, title: String, clinicianID: String, quantity: Int, name: String, reviewer: String, acuity: Int, updatedAt: Int, cost: Double, sequence: Int, status: SubstitutionBudgetStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.quantity = quantity
            self.name = name
            self.reviewer = reviewer
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.cost = cost
            self.sequence = sequence
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

        func canMoveTo(_ next: SubstitutionBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SubstitutionBudgetStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SubstitutionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return (Double(quantity) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionBudget {
            return SubstitutionBudget(
                code: code,
                title: title,
                clinicianID: clinicianID,
                quantity: quantity,
                name: name,
                reviewer: reviewer,
                acuity: acuity,
                updatedAt: updatedAt,
                cost: cost,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution budget in status new.
    static func newSubstitutionBudget(_ code: String, title: String) -> SubstitutionBudget {
        return SubstitutionBudget(
            code: code,
            title: title,
            clinicianID: "",
            quantity: 0,
            name: "",
            reviewer: "",
            acuity: 0,
            updatedAt: 0,
            cost: 0.0,
            sequence: 0,
            status: SubstitutionBudgetStatus.new
        )
    }
}
