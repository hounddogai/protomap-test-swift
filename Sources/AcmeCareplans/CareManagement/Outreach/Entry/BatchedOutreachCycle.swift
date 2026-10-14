import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched outreach cycle is in its life cycle.
    enum BatchedOutreachCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched outreach cycle as the outreach team keeps it.
    final class BatchedOutreachCycle {
        var code: String
        var title: String
        var batchSize: Int
        var name: String
        var encounterID: String
        var clinicianID: String
        var discount: Double
        var status: BatchedOutreachCycleStatus

        init(code: String, title: String, batchSize: Int, name: String, encounterID: String, clinicianID: String, discount: Double, status: BatchedOutreachCycleStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.name = name
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.discount = discount
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

        func canMoveTo(_ next: BatchedOutreachCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedOutreachCycleStatus.pending || next == BatchedOutreachCycleStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedOutreachCycleStatus.suspended || next == BatchedOutreachCycleStatus.closed
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

        func moveTo(_ next: BatchedOutreachCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched outreach cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) + discount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOutreachCycle {
            return BatchedOutreachCycle(
                code: code,
                title: title,
                batchSize: batchSize,
                name: name,
                encounterID: encounterID,
                clinicianID: clinicianID,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched outreach cycle in status draft.
    static func newBatchedOutreachCycle(_ code: String, title: String) -> BatchedOutreachCycle {
        return BatchedOutreachCycle(
            code: code,
            title: title,
            batchSize: 0,
            name: "",
            encounterID: "",
            clinicianID: "",
            discount: 0.0,
            status: BatchedOutreachCycleStatus.draft
        )
    }
}
