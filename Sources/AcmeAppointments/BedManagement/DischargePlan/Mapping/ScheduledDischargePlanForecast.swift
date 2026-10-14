import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled discharge plan forecast is in its life cycle.
    enum ScheduledDischargePlanForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled discharge plan forecast and its current status.
    final class ScheduledDischargePlanForecast {
        var code: String
        var label: String
        var capacity: Int
        var reviewer: String
        var score: Double
        var copay: Double
        var status: ScheduledDischargePlanForecastStatus

        init(code: String, label: String, capacity: Int, reviewer: String, score: Double, copay: Double, status: ScheduledDischargePlanForecastStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.reviewer = reviewer
            self.score = score
            self.copay = copay
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

        func canMoveTo(_ next: ScheduledDischargePlanForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledDischargePlanForecastStatus.inReview || next == ScheduledDischargePlanForecastStatus.resolved
            case .inReview:
                return next == ScheduledDischargePlanForecastStatus.resolved || next == ScheduledDischargePlanForecastStatus.reopened
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: ScheduledDischargePlanForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled discharge plan forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled discharge plan forecast") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(capacity) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledDischargePlanForecast {
            return ScheduledDischargePlanForecast(
                code: code,
                label: label,
                capacity: capacity,
                reviewer: reviewer,
                score: score,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled discharge plan forecast in status open.
    static func newScheduledDischargePlanForecast(_ code: String, label: String) -> ScheduledDischargePlanForecast {
        return ScheduledDischargePlanForecast(
            code: code,
            label: label,
            capacity: 0,
            reviewer: "",
            score: 0.0,
            copay: 0.0,
            status: ScheduledDischargePlanForecastStatus.`open`
        )
    }
}
