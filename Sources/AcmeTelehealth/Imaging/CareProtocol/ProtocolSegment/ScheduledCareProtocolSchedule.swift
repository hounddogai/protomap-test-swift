import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled care protocol schedule is in its life cycle.
    enum ScheduledCareProtocolScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled care protocol schedule as the care protocol team keeps it.
    final class ScheduledCareProtocolSchedule {
        var code: String
        var name: String
        var procedureCode: String
        var durationMinutes: Int
        var ratio: Double
        var timezone: String
        var copay: Double
        var archived: Bool
        var status: ScheduledCareProtocolScheduleStatus

        init(code: String, name: String, procedureCode: String, durationMinutes: Int, ratio: Double, timezone: String, copay: Double, archived: Bool, status: ScheduledCareProtocolScheduleStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.timezone = timezone
            self.copay = copay
            self.archived = archived
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

        func canMoveTo(_ next: ScheduledCareProtocolScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledCareProtocolScheduleStatus.ready || next == ScheduledCareProtocolScheduleStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledCareProtocolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((copay - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareProtocolSchedule {
            return ScheduledCareProtocolSchedule(
                code: code,
                name: name,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                ratio: ratio,
                timezone: timezone,
                copay: copay,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled care protocol schedule in status idle.
    static func newScheduledCareProtocolSchedule(_ code: String, name: String) -> ScheduledCareProtocolSchedule {
        return ScheduledCareProtocolSchedule(
            code: code,
            name: name,
            procedureCode: "",
            durationMinutes: 0,
            ratio: 0.0,
            timezone: "",
            copay: 0.0,
            archived: false,
            status: ScheduledCareProtocolScheduleStatus.idle
        )
    }
}
