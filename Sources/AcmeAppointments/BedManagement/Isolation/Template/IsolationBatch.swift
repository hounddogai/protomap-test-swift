import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation batch is in its life cycle.
    enum IsolationBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One isolation batch, with what the planners need to act on it.
    final class IsolationBatch {
        var code: String
        var label: String
        var rate: Double
        var checksum: String
        var amount: Double
        var bed: String
        var procedureCode: String
        var allergy: String
        var updatedAt: Int
        var budget: Double
        var status: IsolationBatchStatus

        init(code: String, label: String, rate: Double, checksum: String, amount: Double, bed: String, procedureCode: String, allergy: String, updatedAt: Int, budget: Double, status: IsolationBatchStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.checksum = checksum
            self.amount = amount
            self.bed = bed
            self.procedureCode = procedureCode
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.budget = budget
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

        func canMoveTo(_ next: IsolationBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == IsolationBatchStatus.resolved
            case .resolved:
                return next == IsolationBatchStatus.reopened || next == IsolationBatchStatus.archived
            case .reopened:
                return next == IsolationBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((rate + amount) * 100).rounded() / 100
        }

        func copyValue() -> IsolationBatch {
            return IsolationBatch(
                code: code,
                label: label,
                rate: rate,
                checksum: checksum,
                amount: amount,
                bed: bed,
                procedureCode: procedureCode,
                allergy: allergy,
                updatedAt: updatedAt,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation batch in status open.
    static func newIsolationBatch(_ code: String, label: String) -> IsolationBatch {
        return IsolationBatch(
            code: code,
            label: label,
            rate: 0.0,
            checksum: "",
            amount: 0.0,
            bed: "",
            procedureCode: "",
            allergy: "",
            updatedAt: 0,
            budget: 0.0,
            status: IsolationBatchStatus.`open`
        )
    }
}
