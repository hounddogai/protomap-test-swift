import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient priority target is in its life cycle.
    enum LenientPriorityTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a lenient priority target and its current status.
    final class LenientPriorityTarget {
        var code: String
        var label: String
        var graceDays: Int
        var approved: Bool
        var ceiling: Double
        var weight: Double
        var ownerID: String
        var visitMinutes: Int
        var quantity: Int
        var updatedAt: Int
        var status: LenientPriorityTargetStatus

        init(code: String, label: String, graceDays: Int, approved: Bool, ceiling: Double, weight: Double, ownerID: String, visitMinutes: Int, quantity: Int, updatedAt: Int, status: LenientPriorityTargetStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.approved = approved
            self.ceiling = ceiling
            self.weight = weight
            self.ownerID = ownerID
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: LenientPriorityTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientPriorityTargetStatus.stopped
            case .warming:
                return next == LenientPriorityTargetStatus.stopped
            case .ready:
                return next == LenientPriorityTargetStatus.draining
            case .draining:
                return next == LenientPriorityTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientPriorityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient priority target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient priority target") \(code)"
        }

        func weightedTotal() -> Double {
            return ((weight - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LenientPriorityTarget {
            return LenientPriorityTarget(
                code: code,
                label: label,
                graceDays: graceDays,
                approved: approved,
                ceiling: ceiling,
                weight: weight,
                ownerID: ownerID,
                visitMinutes: visitMinutes,
                quantity: quantity,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient priority target in status idle.
    static func newLenientPriorityTarget(_ code: String, label: String) -> LenientPriorityTarget {
        return LenientPriorityTarget(
            code: code,
            label: label,
            graceDays: 0,
            approved: false,
            ceiling: 0.0,
            weight: 0.0,
            ownerID: "",
            visitMinutes: 0,
            quantity: 0,
            updatedAt: 0,
            status: LenientPriorityTargetStatus.idle
        )
    }
}
