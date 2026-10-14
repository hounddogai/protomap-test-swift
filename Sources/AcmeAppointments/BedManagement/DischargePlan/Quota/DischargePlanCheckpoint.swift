import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan checkpoint is in its life cycle.
    enum DischargePlanCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A discharge plan checkpoint as the discharge plan team keeps it.
    final class DischargePlanCheckpoint {
        var code: String
        var title: String
        var contactEmail: String
        var quantity: Int
        var reviewer: String
        var status: DischargePlanCheckpointStatus

        init(code: String, title: String, contactEmail: String, quantity: Int, reviewer: String, status: DischargePlanCheckpointStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DischargePlanCheckpointStatus.approved || next == DischargePlanCheckpointStatus.rejected
            case .approved:
                return next == DischargePlanCheckpointStatus.rejected || next == DischargePlanCheckpointStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DischargePlanCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DischargePlanCheckpoint {
            return DischargePlanCheckpoint(
                code: code,
                title: title,
                contactEmail: contactEmail,
                quantity: quantity,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan checkpoint in status proposed.
    static func newDischargePlanCheckpoint(_ code: String, title: String) -> DischargePlanCheckpoint {
        return DischargePlanCheckpoint(
            code: code,
            title: title,
            contactEmail: "",
            quantity: 0,
            reviewer: "",
            status: DischargePlanCheckpointStatus.proposed
        )
    }
}
