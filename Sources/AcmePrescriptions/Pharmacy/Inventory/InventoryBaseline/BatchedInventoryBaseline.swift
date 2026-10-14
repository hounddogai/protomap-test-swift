import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched inventory baseline is in its life cycle.
    enum BatchedInventoryBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched inventory baseline, with what the planners need to act on it.
    final class BatchedInventoryBaseline {
        var code: String
        var label: String
        var contactEmail: String
        var summary: String
        var payer: String
        var minimum: Double
        var phone: String
        var status: BatchedInventoryBaselineStatus

        init(code: String, label: String, contactEmail: String, summary: String, payer: String, minimum: Double, phone: String, status: BatchedInventoryBaselineStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.summary = summary
            self.payer = payer
            self.minimum = minimum
            self.phone = phone
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

        func canMoveTo(_ next: BatchedInventoryBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedInventoryBaselineStatus.validated || next == BatchedInventoryBaselineStatus.published
            case .validated:
                return next == BatchedInventoryBaselineStatus.published || next == BatchedInventoryBaselineStatus.retired
            case .published:
                return next == BatchedInventoryBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedInventoryBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched inventory baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched inventory baseline") \(code)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> BatchedInventoryBaseline {
            return BatchedInventoryBaseline(
                code: code,
                label: label,
                contactEmail: contactEmail,
                summary: summary,
                payer: payer,
                minimum: minimum,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched inventory baseline in status created.
    static func newBatchedInventoryBaseline(_ code: String, label: String) -> BatchedInventoryBaseline {
        return BatchedInventoryBaseline(
            code: code,
            label: label,
            contactEmail: "",
            summary: "",
            payer: "",
            minimum: 0.0,
            phone: "",
            status: BatchedInventoryBaselineStatus.created
        )
    }
}
