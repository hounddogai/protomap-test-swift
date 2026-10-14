import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense budget is in its life cycle.
    enum DispenseBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A dispense budget as the dispense team keeps it.
    final class DispenseBudget {
        var code: String
        var name: String
        var copay: Double
        var notes: String
        var score: Double
        var batchSize: Int
        var graceDays: Int
        var sequence: Int
        var ratio: Double
        var budget: Double
        var status: DispenseBudgetStatus

        init(code: String, name: String, copay: Double, notes: String, score: Double, batchSize: Int, graceDays: Int, sequence: Int, ratio: Double, budget: Double, status: DispenseBudgetStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.notes = notes
            self.score = score
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.sequence = sequence
            self.ratio = ratio
            self.budget = budget
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

        func canMoveTo(_ next: DispenseBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DispenseBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(batchSize) - score) * 100).rounded() / 100
        }

        func copyValue() -> DispenseBudget {
            return DispenseBudget(
                code: code,
                name: name,
                copay: copay,
                notes: notes,
                score: score,
                batchSize: batchSize,
                graceDays: graceDays,
                sequence: sequence,
                ratio: ratio,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense budget in status draft.
    static func newDispenseBudget(_ code: String, name: String) -> DispenseBudget {
        return DispenseBudget(
            code: code,
            name: name,
            copay: 0.0,
            notes: "",
            score: 0.0,
            batchSize: 0,
            graceDays: 0,
            sequence: 0,
            ratio: 0.0,
            budget: 0.0,
            status: DispenseBudgetStatus.draft
        )
    }
}
