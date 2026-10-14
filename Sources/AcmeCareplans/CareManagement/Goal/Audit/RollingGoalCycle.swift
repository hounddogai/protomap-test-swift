import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling goal cycle is in its life cycle.
    enum RollingGoalCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a rolling goal cycle and its current status.
    final class RollingGoalCycle {
        var code: String
        var title: String
        var allergy: String
        var externalRef: String
        var amount: Double
        var threshold: Double
        var ward: String
        var tags: [String]
        var status: RollingGoalCycleStatus

        init(code: String, title: String, allergy: String, externalRef: String, amount: Double, threshold: Double, ward: String, tags: [String], status: RollingGoalCycleStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.externalRef = externalRef
            self.amount = amount
            self.threshold = threshold
            self.ward = ward
            self.tags = tags
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

        func canMoveTo(_ next: RollingGoalCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingGoalCycleStatus.archived
            case .inReview:
                return next == RollingGoalCycleStatus.resolved
            case .resolved:
                return next == RollingGoalCycleStatus.archived
            case .reopened:
                return next == RollingGoalCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingGoalCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling goal cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((amount - threshold) * 100).rounded() / 100
        }

        func copyValue() -> RollingGoalCycle {
            return RollingGoalCycle(
                code: code,
                title: title,
                allergy: allergy,
                externalRef: externalRef,
                amount: amount,
                threshold: threshold,
                ward: ward,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling goal cycle in status open.
    static func newRollingGoalCycle(_ code: String, title: String) -> RollingGoalCycle {
        return RollingGoalCycle(
            code: code,
            title: title,
            allergy: "",
            externalRef: "",
            amount: 0.0,
            threshold: 0.0,
            ward: "",
            tags: [],
            status: RollingGoalCycleStatus.`open`
        )
    }
}
