import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling care gap schedule is in its life cycle.
    enum RollingCareGapScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling care gap schedule and its current status.
    final class RollingCareGapSchedule {
        var code: String
        var title: String
        var archived: Bool
        var diagnosisCode: String
        var rate: Double
        var capacity: Int
        var currency: String
        var summary: String
        var status: RollingCareGapScheduleStatus

        init(code: String, title: String, archived: Bool, diagnosisCode: String, rate: Double, capacity: Int, currency: String, summary: String, status: RollingCareGapScheduleStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.capacity = capacity
            self.currency = currency
            self.summary = summary
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

        func canMoveTo(_ next: RollingCareGapScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RollingCareGapScheduleStatus.published || next == RollingCareGapScheduleStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingCareGapScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care gap schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return (rate * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareGapSchedule {
            return RollingCareGapSchedule(
                code: code,
                title: title,
                archived: archived,
                diagnosisCode: diagnosisCode,
                rate: rate,
                capacity: capacity,
                currency: currency,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling care gap schedule in status created.
    static func newRollingCareGapSchedule(_ code: String, title: String) -> RollingCareGapSchedule {
        return RollingCareGapSchedule(
            code: code,
            title: title,
            archived: false,
            diagnosisCode: "",
            rate: 0.0,
            capacity: 0,
            currency: "",
            summary: "",
            status: RollingCareGapScheduleStatus.created
        )
    }
}
