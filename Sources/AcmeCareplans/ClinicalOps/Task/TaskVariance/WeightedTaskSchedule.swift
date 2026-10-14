import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted task schedule is in its life cycle.
    enum WeightedTaskScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a weighted task schedule and its current status.
    final class WeightedTaskSchedule {
        var code: String
        var title: String
        var notes: String
        var durationMinutes: Int
        var createdAt: Int
        var encounterID: String
        var retries: Int
        var specialty: String
        var status: WeightedTaskScheduleStatus

        init(code: String, title: String, notes: String, durationMinutes: Int, createdAt: Int, encounterID: String, retries: Int, specialty: String, status: WeightedTaskScheduleStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.createdAt = createdAt
            self.encounterID = encounterID
            self.retries = retries
            self.specialty = specialty
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

        func canMoveTo(_ next: WeightedTaskScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedTaskScheduleStatus.suspended
            case .pending:
                return next == WeightedTaskScheduleStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WeightedTaskScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTaskScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted task schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(durationMinutes) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedTaskSchedule {
            return WeightedTaskSchedule(
                code: code,
                title: title,
                notes: notes,
                durationMinutes: durationMinutes,
                createdAt: createdAt,
                encounterID: encounterID,
                retries: retries,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted task schedule in status draft.
    static func newWeightedTaskSchedule(_ code: String, title: String) -> WeightedTaskSchedule {
        return WeightedTaskSchedule(
            code: code,
            title: title,
            notes: "",
            durationMinutes: 0,
            createdAt: 0,
            encounterID: "",
            retries: 0,
            specialty: "",
            status: WeightedTaskScheduleStatus.draft
        )
    }
}
