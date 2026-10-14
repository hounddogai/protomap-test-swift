import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled bed board target is in its life cycle.
    enum ScheduledBedBoardTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled bed board target. Its code is unique within a tenant.
    final class ScheduledBedBoardTarget {
        var code: String
        var label: String
        var ownerID: String
        var cost: Double
        var graceDays: Int
        var status: ScheduledBedBoardTargetStatus

        init(code: String, label: String, ownerID: String, cost: Double, graceDays: Int, status: ScheduledBedBoardTargetStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.cost = cost
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ScheduledBedBoardTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledBedBoardTargetStatus.published || next == ScheduledBedBoardTargetStatus.retired
            case .validated:
                return next == ScheduledBedBoardTargetStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ScheduledBedBoardTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled bed board target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return (cost * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledBedBoardTarget {
            return ScheduledBedBoardTarget(
                code: code,
                label: label,
                ownerID: ownerID,
                cost: cost,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled bed board target in status created.
    static func newScheduledBedBoardTarget(_ code: String, label: String) -> ScheduledBedBoardTarget {
        return ScheduledBedBoardTarget(
            code: code,
            label: label,
            ownerID: "",
            cost: 0.0,
            graceDays: 0,
            status: ScheduledBedBoardTargetStatus.created
        )
    }
}
