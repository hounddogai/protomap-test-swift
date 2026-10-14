import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled care protocol schedule is in its life cycle.
    enum ScheduledCareProtocolScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled care protocol schedule, with what the planners need to act on it.
    final class ScheduledCareProtocolSchedule {
        var code: String
        var name: String
        var pinned: Bool
        var clinicianID: String
        var facility: String
        var specialty: String
        var approved: Bool
        var updatedAt: Int
        var reviewer: String
        var status: ScheduledCareProtocolScheduleStatus

        init(code: String, name: String, pinned: Bool, clinicianID: String, facility: String, specialty: String, approved: Bool, updatedAt: Int, reviewer: String, status: ScheduledCareProtocolScheduleStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.facility = facility
            self.specialty = specialty
            self.approved = approved
            self.updatedAt = updatedAt
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCareProtocolScheduleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ScheduledCareProtocolScheduleStatus.closed
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
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled care protocol schedule") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> ScheduledCareProtocolSchedule {
            return ScheduledCareProtocolSchedule(
                code: code,
                name: name,
                pinned: pinned,
                clinicianID: clinicianID,
                facility: facility,
                specialty: specialty,
                approved: approved,
                updatedAt: updatedAt,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled care protocol schedule in status draft.
    static func newScheduledCareProtocolSchedule(_ code: String, name: String) -> ScheduledCareProtocolSchedule {
        return ScheduledCareProtocolSchedule(
            code: code,
            name: name,
            pinned: false,
            clinicianID: "",
            facility: "",
            specialty: "",
            approved: false,
            updatedAt: 0,
            reviewer: "",
            status: ScheduledCareProtocolScheduleStatus.draft
        )
    }
}
