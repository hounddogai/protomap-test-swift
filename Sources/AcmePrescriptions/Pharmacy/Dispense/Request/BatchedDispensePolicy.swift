import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched dispense policy is in its life cycle.
    enum BatchedDispensePolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched dispense policy. Its code is unique within a tenant.
    final class BatchedDispensePolicy {
        var code: String
        var title: String
        var cost: Double
        var bed: String
        var reviewer: String
        var approved: Bool
        var payer: String
        var notes: String
        var phone: String
        var status: BatchedDispensePolicyStatus

        init(code: String, title: String, cost: Double, bed: String, reviewer: String, approved: Bool, payer: String, notes: String, phone: String, status: BatchedDispensePolicyStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.bed = bed
            self.reviewer = reviewer
            self.approved = approved
            self.payer = payer
            self.notes = notes
            self.phone = phone
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

        func canMoveTo(_ next: BatchedDispensePolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedDispensePolicyStatus.pending || next == BatchedDispensePolicyStatus.active
            case .pending:
                return next == BatchedDispensePolicyStatus.active || next == BatchedDispensePolicyStatus.suspended
            case .active:
                return next == BatchedDispensePolicyStatus.suspended || next == BatchedDispensePolicyStatus.closed
            case .suspended:
                return next == BatchedDispensePolicyStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDispensePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched dispense policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> BatchedDispensePolicy {
            return BatchedDispensePolicy(
                code: code,
                title: title,
                cost: cost,
                bed: bed,
                reviewer: reviewer,
                approved: approved,
                payer: payer,
                notes: notes,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched dispense policy in status draft.
    static func newBatchedDispensePolicy(_ code: String, title: String) -> BatchedDispensePolicy {
        return BatchedDispensePolicy(
            code: code,
            title: title,
            cost: 0.0,
            bed: "",
            reviewer: "",
            approved: false,
            payer: "",
            notes: "",
            phone: "",
            status: BatchedDispensePolicyStatus.draft
        )
    }
}
