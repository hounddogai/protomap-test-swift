import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study batch is in its life cycle.
    enum RegionalStudyBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a regional study batch and its current status.
    final class RegionalStudyBatch {
        var code: String
        var label: String
        var payer: String
        var capacity: Int
        var cost: Double
        var batchSize: Int
        var revision: Int
        var windowDays: Int
        var procedureCode: String
        var archived: Bool
        var status: RegionalStudyBatchStatus

        init(code: String, label: String, payer: String, capacity: Int, cost: Double, batchSize: Int, revision: Int, windowDays: Int, procedureCode: String, archived: Bool, status: RegionalStudyBatchStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.capacity = capacity
            self.cost = cost
            self.batchSize = batchSize
            self.revision = revision
            self.windowDays = windowDays
            self.procedureCode = procedureCode
            self.archived = archived
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

        func canMoveTo(_ next: RegionalStudyBatchStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RegionalStudyBatchStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RegionalStudyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("regional study batch") \(code)"
        }

        func effectiveTotal() -> Double {
            return (cost * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStudyBatch {
            return RegionalStudyBatch(
                code: code,
                label: label,
                payer: payer,
                capacity: capacity,
                cost: cost,
                batchSize: batchSize,
                revision: revision,
                windowDays: windowDays,
                procedureCode: procedureCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional study batch in status proposed.
    static func newRegionalStudyBatch(_ code: String, label: String) -> RegionalStudyBatch {
        return RegionalStudyBatch(
            code: code,
            label: label,
            payer: "",
            capacity: 0,
            cost: 0.0,
            batchSize: 0,
            revision: 0,
            windowDays: 0,
            procedureCode: "",
            archived: false,
            status: RegionalStudyBatchStatus.proposed
        )
    }
}
