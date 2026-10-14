import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict inventory ledger is in its life cycle.
    enum StrictInventoryLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a strict inventory ledger and its current status.
    final class StrictInventoryLedger {
        var code: String
        var title: String
        var discount: Double
        var patientRef: String
        var batchSize: Int
        var status: StrictInventoryLedgerStatus

        init(code: String, title: String, discount: Double, patientRef: String, batchSize: Int, status: StrictInventoryLedgerStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.patientRef = patientRef
            self.batchSize = batchSize
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

        func canMoveTo(_ next: StrictInventoryLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictInventoryLedgerStatus.inReview || next == StrictInventoryLedgerStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictInventoryLedgerStatus.reopened || next == StrictInventoryLedgerStatus.archived
            case .reopened:
                return next == StrictInventoryLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictInventoryLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict inventory ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict inventory ledger") \(code)"
        }

        func netTotal() -> Double {
            return (discount * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> StrictInventoryLedger {
            return StrictInventoryLedger(
                code: code,
                title: title,
                discount: discount,
                patientRef: patientRef,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict inventory ledger in status open.
    static func newStrictInventoryLedger(_ code: String, title: String) -> StrictInventoryLedger {
        return StrictInventoryLedger(
            code: code,
            title: title,
            discount: 0.0,
            patientRef: "",
            batchSize: 0,
            status: StrictInventoryLedgerStatus.`open`
        )
    }
}
