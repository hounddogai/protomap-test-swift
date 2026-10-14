import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation slot is in its life cycle.
    enum ScheduledRevocationSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled revocation slot as the revocation team keeps it.
    final class ScheduledRevocationSlot {
        var code: String
        var title: String
        var region: String
        var revision: Int
        var ownerID: String
        var endsAt: Int
        var archived: Bool
        var specialty: String
        var status: ScheduledRevocationSlotStatus

        init(code: String, title: String, region: String, revision: Int, ownerID: String, endsAt: Int, archived: Bool, specialty: String, status: ScheduledRevocationSlotStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.revision = revision
            self.ownerID = ownerID
            self.endsAt = endsAt
            self.archived = archived
            self.specialty = specialty
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

        func canMoveTo(_ next: ScheduledRevocationSlotStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledRevocationSlotStatus.scheduled || next == ScheduledRevocationSlotStatus.inProgress
            case .scheduled:
                return next == ScheduledRevocationSlotStatus.completed || next == ScheduledRevocationSlotStatus.cancelled
            case .inProgress:
                return next == ScheduledRevocationSlotStatus.completed || next == ScheduledRevocationSlotStatus.cancelled
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

        func moveTo(_ next: ScheduledRevocationSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((Double(revision) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRevocationSlot {
            return ScheduledRevocationSlot(
                code: code,
                title: title,
                region: region,
                revision: revision,
                ownerID: ownerID,
                endsAt: endsAt,
                archived: archived,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled revocation slot in status planned.
    static func newScheduledRevocationSlot(_ code: String, title: String) -> ScheduledRevocationSlot {
        return ScheduledRevocationSlot(
            code: code,
            title: title,
            region: "",
            revision: 0,
            ownerID: "",
            endsAt: 0,
            archived: false,
            specialty: "",
            status: ScheduledRevocationSlotStatus.planned
        )
    }
}
