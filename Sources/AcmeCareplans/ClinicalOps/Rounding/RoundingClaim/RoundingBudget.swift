import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding budget is in its life cycle.
    enum RoundingBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a rounding budget and its current status.
    final class RoundingBudget {
        var code: String
        var title: String
        var encounterID: String
        var batchSize: Int
        var threshold: Double
        var segment: String
        var status: RoundingBudgetStatus

        init(code: String, title: String, encounterID: String, batchSize: Int, threshold: Double, segment: String, status: RoundingBudgetStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.batchSize = batchSize
            self.threshold = threshold
            self.segment = segment
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

        func canMoveTo(_ next: RoundingBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RoundingBudgetStatus.active || next == RoundingBudgetStatus.suspended
            case .active:
                return next == RoundingBudgetStatus.suspended
            case .suspended:
                return next == RoundingBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((Double(batchSize) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> RoundingBudget {
            return RoundingBudget(
                code: code,
                title: title,
                encounterID: encounterID,
                batchSize: batchSize,
                threshold: threshold,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rounding budget in status draft.
    static func newRoundingBudget(_ code: String, title: String) -> RoundingBudget {
        return RoundingBudget(
            code: code,
            title: title,
            encounterID: "",
            batchSize: 0,
            threshold: 0.0,
            segment: "",
            status: RoundingBudgetStatus.draft
        )
    }
}
