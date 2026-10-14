import AcmePlatform
import Foundation

extension Labs {
    /// Where a result slot is in its life cycle.
    enum ResultSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a result slot and its current status.
    final class ResultSlot {
        var code: String
        var label: String
        var threshold: Double
        var description: String
        var capacity: Int
        var version: Int
        var currency: String
        var expiresAt: Int
        var bed: String
        var quantity: Int
        var visitMinutes: Int
        var status: ResultSlotStatus

        init(code: String, label: String, threshold: Double, description: String, capacity: Int, version: Int, currency: String, expiresAt: Int, bed: String, quantity: Int, visitMinutes: Int, status: ResultSlotStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.description = description
            self.capacity = capacity
            self.version = version
            self.currency = currency
            self.expiresAt = expiresAt
            self.bed = bed
            self.quantity = quantity
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ResultSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == ResultSlotStatus.pending || next == ResultSlotStatus.closed
            case .pending:
                return next == ResultSlotStatus.suspended || next == ResultSlotStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ResultSlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedVolume() -> Double {
            return (threshold * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> ResultSlot {
            return ResultSlot(
                code: code,
                label: label,
                threshold: threshold,
                description: description,
                capacity: capacity,
                version: version,
                currency: currency,
                expiresAt: expiresAt,
                bed: bed,
                quantity: quantity,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a result slot in status draft.
    static func newResultSlot(_ code: String, label: String) -> ResultSlot {
        return ResultSlot(
            code: code,
            label: label,
            threshold: 0.0,
            description: "",
            capacity: 0,
            version: 0,
            currency: "",
            expiresAt: 0,
            bed: "",
            quantity: 0,
            visitMinutes: 0,
            status: ResultSlotStatus.draft
        )
    }
}
