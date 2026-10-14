import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict slot batch is in its life cycle.
    enum StrictSlotBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict slot batch. Its code is unique within a tenant.
    final class StrictSlotBatch {
        var code: String
        var label: String
        var clinicianID: String
        var unit: String
        var contactEmail: String
        var ownerID: String
        var quantity: Int
        var status: StrictSlotBatchStatus

        init(code: String, label: String, clinicianID: String, unit: String, contactEmail: String, ownerID: String, quantity: Int, status: StrictSlotBatchStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.unit = unit
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.quantity = quantity
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

        func canMoveTo(_ next: StrictSlotBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictSlotBatchStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictSlotBatchStatus.reopened || next == StrictSlotBatchStatus.archived
            case .reopened:
                return next == StrictSlotBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSlotBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict slot batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict slot batch") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> StrictSlotBatch {
            return StrictSlotBatch(
                code: code,
                label: label,
                clinicianID: clinicianID,
                unit: unit,
                contactEmail: contactEmail,
                ownerID: ownerID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict slot batch in status open.
    static func newStrictSlotBatch(_ code: String, label: String) -> StrictSlotBatch {
        return StrictSlotBatch(
            code: code,
            label: label,
            clinicianID: "",
            unit: "",
            contactEmail: "",
            ownerID: "",
            quantity: 0,
            status: StrictSlotBatchStatus.`open`
        )
    }
}
