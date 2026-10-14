import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending goal schedule is in its life cycle.
    enum PendingGoalScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending goal schedule, with what the planners need to act on it.
    final class PendingGoalSchedule {
        var code: String
        var name: String
        var weight: Double
        var bed: String
        var approved: Bool
        var expiresAt: Int
        var reviewer: String
        var revision: Int
        var capacity: Int
        var specialty: String
        var visitMinutes: Int
        var status: PendingGoalScheduleStatus

        init(code: String, name: String, weight: Double, bed: String, approved: Bool, expiresAt: Int, reviewer: String, revision: Int, capacity: Int, specialty: String, visitMinutes: Int, status: PendingGoalScheduleStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.bed = bed
            self.approved = approved
            self.expiresAt = expiresAt
            self.reviewer = reviewer
            self.revision = revision
            self.capacity = capacity
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingGoalScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PendingGoalScheduleStatus.rejected || next == PendingGoalScheduleStatus.withdrawn
            case .rejected:
                return next == PendingGoalScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingGoalScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending goal schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((Double(revision) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingGoalSchedule {
            return PendingGoalSchedule(
                code: code,
                name: name,
                weight: weight,
                bed: bed,
                approved: approved,
                expiresAt: expiresAt,
                reviewer: reviewer,
                revision: revision,
                capacity: capacity,
                specialty: specialty,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending goal schedule in status proposed.
    static func newPendingGoalSchedule(_ code: String, name: String) -> PendingGoalSchedule {
        return PendingGoalSchedule(
            code: code,
            name: name,
            weight: 0.0,
            bed: "",
            approved: false,
            expiresAt: 0,
            reviewer: "",
            revision: 0,
            capacity: 0,
            specialty: "",
            visitMinutes: 0,
            status: PendingGoalScheduleStatus.proposed
        )
    }
}
