import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap plan is in its life cycle.
    enum SeasonalCareGapPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal care gap plan. Its code is unique within a tenant.
    final class SeasonalCareGapPlan {
        var code: String
        var title: String
        var phone: String
        var amount: Double
        var contactEmail: String
        var pinned: Bool
        var status: SeasonalCareGapPlanStatus

        init(code: String, title: String, phone: String, amount: Double, contactEmail: String, pinned: Bool, status: SeasonalCareGapPlanStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.amount = amount
            self.contactEmail = contactEmail
            self.pinned = pinned
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

        func canMoveTo(_ next: SeasonalCareGapPlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalCareGapPlanStatus.inProgress || next == SeasonalCareGapPlanStatus.cancelled
            case .scheduled:
                return next == SeasonalCareGapPlanStatus.inProgress || next == SeasonalCareGapPlanStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SeasonalCareGapPlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCareGapPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> SeasonalCareGapPlan {
            return SeasonalCareGapPlan(
                code: code,
                title: title,
                phone: phone,
                amount: amount,
                contactEmail: contactEmail,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal care gap plan in status planned.
    static func newSeasonalCareGapPlan(_ code: String, title: String) -> SeasonalCareGapPlan {
        return SeasonalCareGapPlan(
            code: code,
            title: title,
            phone: "",
            amount: 0.0,
            contactEmail: "",
            pinned: false,
            status: SeasonalCareGapPlanStatus.planned
        )
    }
}
