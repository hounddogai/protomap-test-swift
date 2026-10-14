import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot assignment is in its life cycle.
    enum SlotAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A slot assignment. Its code is unique within a tenant.
    final class SlotAssignment {
        var code: String
        var label: String
        var margin: Double
        var payer: String
        var quantity: Int
        var ratio: Double
        var priority: Int
        var status: SlotAssignmentStatus

        init(code: String, label: String, margin: Double, payer: String, quantity: Int, ratio: Double, priority: Int, status: SlotAssignmentStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.payer = payer
            self.quantity = quantity
            self.ratio = ratio
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == SlotAssignmentStatus.ready || next == SlotAssignmentStatus.draining
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SlotAssignmentStatus.stopped
            case .draining:
                return next == SlotAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("slot assignment") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(priority) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> SlotAssignment {
            return SlotAssignment(
                code: code,
                label: label,
                margin: margin,
                payer: payer,
                quantity: quantity,
                ratio: ratio,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a slot assignment in status idle.
    static func newSlotAssignment(_ code: String, label: String) -> SlotAssignment {
        return SlotAssignment(
            code: code,
            label: label,
            margin: 0.0,
            payer: "",
            quantity: 0,
            ratio: 0.0,
            priority: 0,
            status: SlotAssignmentStatus.idle
        )
    }
}
