import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending slot target is in its life cycle.
    enum PendingSlotTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending slot target and its current status.
    final class PendingSlotTarget {
        var code: String
        var name: String
        var checksum: String
        var archived: Bool
        var procedureCode: String
        var active: Bool
        var allergy: String
        var amount: Double
        var status: PendingSlotTargetStatus

        init(code: String, name: String, checksum: String, archived: Bool, procedureCode: String, active: Bool, allergy: String, amount: Double, status: PendingSlotTargetStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.archived = archived
            self.procedureCode = procedureCode
            self.active = active
            self.allergy = allergy
            self.amount = amount
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

        func canMoveTo(_ next: PendingSlotTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PendingSlotTargetStatus.completed || next == PendingSlotTargetStatus.cancelled
            case .inProgress:
                return next == PendingSlotTargetStatus.cancelled
            case .completed:
                return next == PendingSlotTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSlotTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending slot target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> PendingSlotTarget {
            return PendingSlotTarget(
                code: code,
                name: name,
                checksum: checksum,
                archived: archived,
                procedureCode: procedureCode,
                active: active,
                allergy: allergy,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending slot target in status planned.
    static func newPendingSlotTarget(_ code: String, name: String) -> PendingSlotTarget {
        return PendingSlotTarget(
            code: code,
            name: name,
            checksum: "",
            archived: false,
            procedureCode: "",
            active: false,
            allergy: "",
            amount: 0.0,
            status: PendingSlotTargetStatus.planned
        )
    }
}
