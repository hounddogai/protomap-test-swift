import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist plan is in its life cycle.
    enum WorklistPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist plan. Its code is unique within a tenant.
    final class WorklistPlan {
        var code: String
        var title: String
        var tags: [String]
        var startsAt: Int
        var graceDays: Int
        var amount: Double
        var label: String
        var visible: Bool
        var status: WorklistPlanStatus

        init(code: String, title: String, tags: [String], startsAt: Int, graceDays: Int, amount: Double, label: String, visible: Bool, status: WorklistPlanStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.startsAt = startsAt
            self.graceDays = graceDays
            self.amount = amount
            self.label = label
            self.visible = visible
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

        func canMoveTo(_ next: WorklistPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistPlanStatus.rejected || next == WorklistPlanStatus.withdrawn
            case .approved:
                return next == WorklistPlanStatus.withdrawn
            case .rejected:
                return next == WorklistPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("worklist plan") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((Double(graceDays) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistPlan {
            return WorklistPlan(
                code: code,
                title: title,
                tags: tags,
                startsAt: startsAt,
                graceDays: graceDays,
                amount: amount,
                label: label,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist plan in status proposed.
    static func newWorklistPlan(_ code: String, title: String) -> WorklistPlan {
        return WorklistPlan(
            code: code,
            title: title,
            tags: [],
            startsAt: 0,
            graceDays: 0,
            amount: 0.0,
            label: "",
            visible: false,
            status: WorklistPlanStatus.proposed
        )
    }
}
