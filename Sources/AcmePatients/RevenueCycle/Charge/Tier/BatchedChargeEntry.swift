import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched charge entry is in its life cycle.
    enum BatchedChargeEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a batched charge entry and its current status.
    final class BatchedChargeEntry {
        var code: String
        var label: String
        var name: String
        var durationMinutes: Int
        var quantity: Int
        var capacity: Int
        var graceDays: Int
        var contactEmail: String
        var createdAt: Int
        var status: BatchedChargeEntryStatus

        init(code: String, label: String, name: String, durationMinutes: Int, quantity: Int, capacity: Int, graceDays: Int, contactEmail: String, createdAt: Int, status: BatchedChargeEntryStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.capacity = capacity
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.createdAt = createdAt
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

        func canMoveTo(_ next: BatchedChargeEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedChargeEntryStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == BatchedChargeEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedChargeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched charge entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return (Double(capacity) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> BatchedChargeEntry {
            return BatchedChargeEntry(
                code: code,
                label: label,
                name: name,
                durationMinutes: durationMinutes,
                quantity: quantity,
                capacity: capacity,
                graceDays: graceDays,
                contactEmail: contactEmail,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched charge entry in status draft.
    static func newBatchedChargeEntry(_ code: String, label: String) -> BatchedChargeEntry {
        return BatchedChargeEntry(
            code: code,
            label: label,
            name: "",
            durationMinutes: 0,
            quantity: 0,
            capacity: 0,
            graceDays: 0,
            contactEmail: "",
            createdAt: 0,
            status: BatchedChargeEntryStatus.draft
        )
    }
}
