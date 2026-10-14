import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped cleaning score is in its life cycle.
    enum CappedCleaningScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped cleaning score, with what the planners need to act on it.
    final class CappedCleaningScore {
        var code: String
        var label: String
        var timezone: String
        var segment: String
        var acuity: Int
        var locale: String
        var cost: Double
        var specialty: String
        var rate: Double
        var durationMinutes: Int
        var status: CappedCleaningScoreStatus

        init(code: String, label: String, timezone: String, segment: String, acuity: Int, locale: String, cost: Double, specialty: String, rate: Double, durationMinutes: Int, status: CappedCleaningScoreStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.segment = segment
            self.acuity = acuity
            self.locale = locale
            self.cost = cost
            self.specialty = specialty
            self.rate = rate
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: CappedCleaningScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedCleaningScoreStatus.completed
            case .inProgress:
                return next == CappedCleaningScoreStatus.completed
            case .completed:
                return next == CappedCleaningScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCleaningScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped cleaning score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped cleaning score") \(code)"
        }

        func weightedLoad() -> Double {
            return ((rate - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCleaningScore {
            return CappedCleaningScore(
                code: code,
                label: label,
                timezone: timezone,
                segment: segment,
                acuity: acuity,
                locale: locale,
                cost: cost,
                specialty: specialty,
                rate: rate,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped cleaning score in status planned.
    static func newCappedCleaningScore(_ code: String, label: String) -> CappedCleaningScore {
        return CappedCleaningScore(
            code: code,
            label: label,
            timezone: "",
            segment: "",
            acuity: 0,
            locale: "",
            cost: 0.0,
            specialty: "",
            rate: 0.0,
            durationMinutes: 0,
            status: CappedCleaningScoreStatus.planned
        )
    }
}
