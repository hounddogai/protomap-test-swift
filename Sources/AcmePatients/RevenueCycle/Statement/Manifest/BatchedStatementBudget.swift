import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched statement budget is in its life cycle.
    enum BatchedStatementBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched statement budget as the statement team keeps it.
    final class BatchedStatementBudget {
        var code: String
        var name: String
        var createdAt: Int
        var updatedAt: Int
        var patientRef: String
        var description: String
        var status: BatchedStatementBudgetStatus

        init(code: String, name: String, createdAt: Int, updatedAt: Int, patientRef: String, description: String, status: BatchedStatementBudgetStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.description = description
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

        func canMoveTo(_ next: BatchedStatementBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BatchedStatementBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched statement budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return (Double(updatedAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStatementBudget {
            return BatchedStatementBudget(
                code: code,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                patientRef: patientRef,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched statement budget in status created.
    static func newBatchedStatementBudget(_ code: String, name: String) -> BatchedStatementBudget {
        return BatchedStatementBudget(
            code: code,
            name: name,
            createdAt: 0,
            updatedAt: 0,
            patientRef: "",
            description: "",
            status: BatchedStatementBudgetStatus.created
        )
    }
}
