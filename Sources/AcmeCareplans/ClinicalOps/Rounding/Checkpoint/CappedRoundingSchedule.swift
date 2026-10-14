import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped rounding schedule is in its life cycle.
    enum CappedRoundingScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped rounding schedule, with what the planners need to act on it.
    final class CappedRoundingSchedule {
        var code: String
        var label: String
        var weight: Double
        var durationMinutes: Int
        var region: String
        var status: CappedRoundingScheduleStatus

        init(code: String, label: String, weight: Double, durationMinutes: Int, region: String, status: CappedRoundingScheduleStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.region = region
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

        func canMoveTo(_ next: CappedRoundingScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedRoundingScheduleStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedRoundingScheduleStatus.completed || next == CappedRoundingScheduleStatus.cancelled
            case .completed:
                return next == CappedRoundingScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRoundingScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped rounding schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped rounding schedule") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) + weight) * 100).rounded() / 100
        }

        func copyValue() -> CappedRoundingSchedule {
            return CappedRoundingSchedule(
                code: code,
                label: label,
                weight: weight,
                durationMinutes: durationMinutes,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped rounding schedule in status planned.
    static func newCappedRoundingSchedule(_ code: String, label: String) -> CappedRoundingSchedule {
        return CappedRoundingSchedule(
            code: code,
            label: label,
            weight: 0.0,
            durationMinutes: 0,
            region: "",
            status: CappedRoundingScheduleStatus.planned
        )
    }
}
