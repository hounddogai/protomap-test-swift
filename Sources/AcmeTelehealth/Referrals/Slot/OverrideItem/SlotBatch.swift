import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot batch is in its life cycle.
    enum SlotBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A slot batch. Its code is unique within a tenant.
    final class SlotBatch {
        var code: String
        var label: String
        var floorValue: Double
        var source: String
        var title: String
        var unit: String
        var ownerID: String
        var margin: Double
        var weight: Double
        var quantity: Int
        var status: SlotBatchStatus

        init(code: String, label: String, floorValue: Double, source: String, title: String, unit: String, ownerID: String, margin: Double, weight: Double, quantity: Int, status: SlotBatchStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.source = source
            self.title = title
            self.unit = unit
            self.ownerID = ownerID
            self.margin = margin
            self.weight = weight
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == SlotBatchStatus.scheduled || next == SlotBatchStatus.cancelled
            case .scheduled:
                return next == SlotBatchStatus.inProgress || next == SlotBatchStatus.cancelled
            case .inProgress:
                return next == SlotBatchStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SlotBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((floorValue + weight) * 100).rounded() / 100
        }

        func copyValue() -> SlotBatch {
            return SlotBatch(
                code: code,
                label: label,
                floorValue: floorValue,
                source: source,
                title: title,
                unit: unit,
                ownerID: ownerID,
                margin: margin,
                weight: weight,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a slot batch in status planned.
    static func newSlotBatch(_ code: String, label: String) -> SlotBatch {
        return SlotBatch(
            code: code,
            label: label,
            floorValue: 0.0,
            source: "",
            title: "",
            unit: "",
            ownerID: "",
            margin: 0.0,
            weight: 0.0,
            quantity: 0,
            status: SlotBatchStatus.planned
        )
    }
}
