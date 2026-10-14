import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up schedule is in its life cycle.
    enum FollowUpScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A follow up schedule. Its code is unique within a tenant.
    final class FollowUpSchedule {
        var code: String
        var label: String
        var amount: Double
        var ownerID: String
        var cost: Double
        var name: String
        var status: FollowUpScheduleStatus

        init(code: String, label: String, amount: Double, ownerID: String, cost: Double, name: String, status: FollowUpScheduleStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.ownerID = ownerID
            self.cost = cost
            self.name = name
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

        func canMoveTo(_ next: FollowUpScheduleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FollowUpScheduleStatus.failed
            case .done:
                return next == FollowUpScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up schedule") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((cost + amount) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpSchedule {
            return FollowUpSchedule(
                code: code,
                label: label,
                amount: amount,
                ownerID: ownerID,
                cost: cost,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up schedule in status new.
    static func newFollowUpSchedule(_ code: String, label: String) -> FollowUpSchedule {
        return FollowUpSchedule(
            code: code,
            label: label,
            amount: 0.0,
            ownerID: "",
            cost: 0.0,
            name: "",
            status: FollowUpScheduleStatus.new
        )
    }
}
