import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling alert review is in its life cycle.
    enum RollingAlertReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling alert review as the alert team keeps it.
    final class RollingAlertReview {
        var code: String
        var name: String
        var cost: Double
        var weight: Double
        var approved: Bool
        var reviewer: String
        var floorValue: Double
        var locale: String
        var amount: Double
        var status: RollingAlertReviewStatus

        init(code: String, name: String, cost: Double, weight: Double, approved: Bool, reviewer: String, floorValue: Double, locale: String, amount: Double, status: RollingAlertReviewStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.weight = weight
            self.approved = approved
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.locale = locale
            self.amount = amount
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

        func canMoveTo(_ next: RollingAlertReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingAlertReviewStatus.approved || next == RollingAlertReviewStatus.withdrawn
            case .approved:
                return next == RollingAlertReviewStatus.withdrawn
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

        func moveTo(_ next: RollingAlertReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling alert review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return (cost * weight * 100).rounded() / 100
        }

        func copyValue() -> RollingAlertReview {
            return RollingAlertReview(
                code: code,
                name: name,
                cost: cost,
                weight: weight,
                approved: approved,
                reviewer: reviewer,
                floorValue: floorValue,
                locale: locale,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling alert review in status proposed.
    static func newRollingAlertReview(_ code: String, name: String) -> RollingAlertReview {
        return RollingAlertReview(
            code: code,
            name: name,
            cost: 0.0,
            weight: 0.0,
            approved: false,
            reviewer: "",
            floorValue: 0.0,
            locale: "",
            amount: 0.0,
            status: RollingAlertReviewStatus.proposed
        )
    }
}
