import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap schedule is in its life cycle.
    enum CareGapScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One care gap schedule, with what the planners need to act on it.
    final class CareGapSchedule {
        var code: String
        var title: String
        var attempts: Int
        var floorValue: Double
        var threshold: Double
        var region: String
        var facility: String
        var createdAt: Int
        var status: CareGapScheduleStatus

        init(code: String, title: String, attempts: Int, floorValue: Double, threshold: Double, region: String, facility: String, createdAt: Int, status: CareGapScheduleStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.floorValue = floorValue
            self.threshold = threshold
            self.region = region
            self.facility = facility
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CareGapScheduleStatus) -> Bool {
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
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CareGapScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (floorValue * threshold * 100).rounded() / 100
        }

        func copyValue() -> CareGapSchedule {
            return CareGapSchedule(
                code: code,
                title: title,
                attempts: attempts,
                floorValue: floorValue,
                threshold: threshold,
                region: region,
                facility: facility,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care gap schedule in status planned.
    static func newCareGapSchedule(_ code: String, title: String) -> CareGapSchedule {
        return CareGapSchedule(
            code: code,
            title: title,
            attempts: 0,
            floorValue: 0.0,
            threshold: 0.0,
            region: "",
            facility: "",
            createdAt: 0,
            status: CareGapScheduleStatus.planned
        )
    }
}
