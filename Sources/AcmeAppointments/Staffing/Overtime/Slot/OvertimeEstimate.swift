import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime estimate is in its life cycle.
    enum OvertimeEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A overtime estimate as the overtime team keeps it.
    final class OvertimeEstimate {
        var code: String
        var label: String
        var score: Double
        var weight: Double
        var graceDays: Int
        var cost: Double
        var maximum: Double
        var locale: String
        var status: OvertimeEstimateStatus

        init(code: String, label: String, score: Double, weight: Double, graceDays: Int, cost: Double, maximum: Double, locale: String, status: OvertimeEstimateStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.weight = weight
            self.graceDays = graceDays
            self.cost = cost
            self.maximum = maximum
            self.locale = locale
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

        func canMoveTo(_ next: OvertimeEstimateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == OvertimeEstimateStatus.published || next == OvertimeEstimateStatus.retired
            case .published:
                return next == OvertimeEstimateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("overtime estimate") \(code)"
        }

        func weightedLoad() -> Double {
            return ((score + maximum) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeEstimate {
            return OvertimeEstimate(
                code: code,
                label: label,
                score: score,
                weight: weight,
                graceDays: graceDays,
                cost: cost,
                maximum: maximum,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a overtime estimate in status created.
    static func newOvertimeEstimate(_ code: String, label: String) -> OvertimeEstimate {
        return OvertimeEstimate(
            code: code,
            label: label,
            score: 0.0,
            weight: 0.0,
            graceDays: 0,
            cost: 0.0,
            maximum: 0.0,
            locale: "",
            status: OvertimeEstimateStatus.created
        )
    }
}
