import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal adjustment is in its life cycle.
    enum GoalAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One goal adjustment, with what the planners need to act on it.
    final class GoalAdjustment {
        var code: String
        var name: String
        var region: String
        var ward: String
        var currency: String
        var diagnosisCode: String
        var quantity: Int
        var status: GoalAdjustmentStatus

        init(code: String, name: String, region: String, ward: String, currency: String, diagnosisCode: String, quantity: Int, status: GoalAdjustmentStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.ward = ward
            self.currency = currency
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == GoalAdjustmentStatus.ready || next == GoalAdjustmentStatus.draining
            case .warming:
                return next == GoalAdjustmentStatus.draining
            case .ready:
                return next == GoalAdjustmentStatus.stopped
            case .draining:
                return next == GoalAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("goal adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> GoalAdjustment {
            return GoalAdjustment(
                code: code,
                name: name,
                region: region,
                ward: ward,
                currency: currency,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a goal adjustment in status idle.
    static func newGoalAdjustment(_ code: String, name: String) -> GoalAdjustment {
        return GoalAdjustment(
            code: code,
            name: name,
            region: "",
            ward: "",
            currency: "",
            diagnosisCode: "",
            quantity: 0,
            status: GoalAdjustmentStatus.idle
        )
    }
}
