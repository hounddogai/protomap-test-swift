import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient discharge plan milestone is in its life cycle.
    enum LenientDischargePlanMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient discharge plan milestone and its current status.
    final class LenientDischargePlanMilestone {
        var code: String
        var name: String
        var approved: Bool
        var priority: Int
        var budget: Double
        var discount: Double
        var visible: Bool
        var limit: Int
        var segment: String
        var status: LenientDischargePlanMilestoneStatus

        init(code: String, name: String, approved: Bool, priority: Int, budget: Double, discount: Double, visible: Bool, limit: Int, segment: String, status: LenientDischargePlanMilestoneStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.priority = priority
            self.budget = budget
            self.discount = discount
            self.visible = visible
            self.limit = limit
            self.segment = segment
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

        func canMoveTo(_ next: LenientDischargePlanMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientDischargePlanMilestoneStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientDischargePlanMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDischargePlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient discharge plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient discharge plan milestone") \(code)"
        }

        func weightedTotal() -> Double {
            return ((budget - discount) * 100).rounded() / 100
        }

        func copyValue() -> LenientDischargePlanMilestone {
            return LenientDischargePlanMilestone(
                code: code,
                name: name,
                approved: approved,
                priority: priority,
                budget: budget,
                discount: discount,
                visible: visible,
                limit: limit,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient discharge plan milestone in status open.
    static func newLenientDischargePlanMilestone(_ code: String, name: String) -> LenientDischargePlanMilestone {
        return LenientDischargePlanMilestone(
            code: code,
            name: name,
            approved: false,
            priority: 0,
            budget: 0.0,
            discount: 0.0,
            visible: false,
            limit: 0,
            segment: "",
            status: LenientDischargePlanMilestoneStatus.`open`
        )
    }
}
