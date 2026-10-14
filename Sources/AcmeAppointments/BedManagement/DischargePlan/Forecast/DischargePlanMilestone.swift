import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan milestone is in its life cycle.
    enum DischargePlanMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a discharge plan milestone and its current status.
    final class DischargePlanMilestone {
        var code: String
        var title: String
        var bed: String
        var copay: Double
        var procedureCode: String
        var archived: Bool
        var status: DischargePlanMilestoneStatus

        init(code: String, title: String, bed: String, copay: Double, procedureCode: String, archived: Bool, status: DischargePlanMilestoneStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.copay = copay
            self.procedureCode = procedureCode
            self.archived = archived
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

        func canMoveTo(_ next: DischargePlanMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DischargePlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> DischargePlanMilestone {
            return DischargePlanMilestone(
                code: code,
                title: title,
                bed: bed,
                copay: copay,
                procedureCode: procedureCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan milestone in status open.
    static func newDischargePlanMilestone(_ code: String, title: String) -> DischargePlanMilestone {
        return DischargePlanMilestone(
            code: code,
            title: title,
            bed: "",
            copay: 0.0,
            procedureCode: "",
            archived: false,
            status: DischargePlanMilestoneStatus.`open`
        )
    }
}
