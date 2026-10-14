import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach slot is in its life cycle.
    enum LenientOutreachSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient outreach slot. Its code is unique within a tenant.
    final class LenientOutreachSlot {
        var code: String
        var title: String
        var clinicianID: String
        var capacity: Int
        var amount: Double
        var status: LenientOutreachSlotStatus

        init(code: String, title: String, clinicianID: String, capacity: Int, amount: Double, status: LenientOutreachSlotStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.capacity = capacity
            self.amount = amount
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

        func canMoveTo(_ next: LenientOutreachSlotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientOutreachSlotStatus.inReview || next == LenientOutreachSlotStatus.archived
            case .inReview:
                return next == LenientOutreachSlotStatus.resolved || next == LenientOutreachSlotStatus.reopened
            case .resolved:
                return next == LenientOutreachSlotStatus.reopened || next == LenientOutreachSlotStatus.archived
            case .reopened:
                return next == LenientOutreachSlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientOutreachSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient outreach slot") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(capacity) + amount) * 100).rounded() / 100
        }

        func copyValue() -> LenientOutreachSlot {
            return LenientOutreachSlot(
                code: code,
                title: title,
                clinicianID: clinicianID,
                capacity: capacity,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient outreach slot in status open.
    static func newLenientOutreachSlot(_ code: String, title: String) -> LenientOutreachSlot {
        return LenientOutreachSlot(
            code: code,
            title: title,
            clinicianID: "",
            capacity: 0,
            amount: 0.0,
            status: LenientOutreachSlotStatus.`open`
        )
    }
}
