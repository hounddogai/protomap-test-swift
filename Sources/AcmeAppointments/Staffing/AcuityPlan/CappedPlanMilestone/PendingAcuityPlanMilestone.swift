import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending acuity plan milestone is in its life cycle.
    enum PendingAcuityPlanMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending acuity plan milestone. Its code is unique within a tenant.
    final class PendingAcuityPlanMilestone {
        var code: String
        var label: String
        var visible: Bool
        var ownerID: String
        var title: String
        var reviewer: String
        var approved: Bool
        var quantity: Int
        var status: PendingAcuityPlanMilestoneStatus

        init(code: String, label: String, visible: Bool, ownerID: String, title: String, reviewer: String, approved: Bool, quantity: Int, status: PendingAcuityPlanMilestoneStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.ownerID = ownerID
            self.title = title
            self.reviewer = reviewer
            self.approved = approved
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingAcuityPlanMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingAcuityPlanMilestoneStatus.done || next == PendingAcuityPlanMilestoneStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PendingAcuityPlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending acuity plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending acuity plan milestone") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> PendingAcuityPlanMilestone {
            return PendingAcuityPlanMilestone(
                code: code,
                label: label,
                visible: visible,
                ownerID: ownerID,
                title: title,
                reviewer: reviewer,
                approved: approved,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending acuity plan milestone in status new.
    static func newPendingAcuityPlanMilestone(_ code: String, label: String) -> PendingAcuityPlanMilestone {
        return PendingAcuityPlanMilestone(
            code: code,
            label: label,
            visible: false,
            ownerID: "",
            title: "",
            reviewer: "",
            approved: false,
            quantity: 0,
            status: PendingAcuityPlanMilestoneStatus.new
        )
    }
}
