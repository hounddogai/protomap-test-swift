import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending eligibility forecast is in its life cycle.
    enum PendingEligibilityForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending eligibility forecast, with what the planners need to act on it.
    final class PendingEligibilityForecast {
        var code: String
        var label: String
        var cost: Double
        var bed: String
        var clinicianID: String
        var priority: Int
        var graceDays: Int
        var status: PendingEligibilityForecastStatus

        init(code: String, label: String, cost: Double, bed: String, clinicianID: String, priority: Int, graceDays: Int, status: PendingEligibilityForecastStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.bed = bed
            self.clinicianID = clinicianID
            self.priority = priority
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PendingEligibilityForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingEligibilityForecastStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingEligibilityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending eligibility forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return (Double(priority) * cost * 100).rounded() / 100
        }

        func copyValue() -> PendingEligibilityForecast {
            return PendingEligibilityForecast(
                code: code,
                label: label,
                cost: cost,
                bed: bed,
                clinicianID: clinicianID,
                priority: priority,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending eligibility forecast in status planned.
    static func newPendingEligibilityForecast(_ code: String, label: String) -> PendingEligibilityForecast {
        return PendingEligibilityForecast(
            code: code,
            label: label,
            cost: 0.0,
            bed: "",
            clinicianID: "",
            priority: 0,
            graceDays: 0,
            status: PendingEligibilityForecastStatus.planned
        )
    }
}
