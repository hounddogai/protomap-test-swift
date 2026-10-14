import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending follow up reservation is in its life cycle.
    enum PendingFollowUpReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending follow up reservation and its current status.
    final class PendingFollowUpReservation {
        var code: String
        var label: String
        var ownerID: String
        var approved: Bool
        var revision: Int
        var createdAt: Int
        var facility: String
        var archived: Bool
        var weight: Double
        var status: PendingFollowUpReservationStatus

        init(code: String, label: String, ownerID: String, approved: Bool, revision: Int, createdAt: Int, facility: String, archived: Bool, weight: Double, status: PendingFollowUpReservationStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.approved = approved
            self.revision = revision
            self.createdAt = createdAt
            self.facility = facility
            self.archived = archived
            self.weight = weight
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

        func canMoveTo(_ next: PendingFollowUpReservationStatus) -> Bool {
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
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingFollowUpReservationStatus.completed || next == PendingFollowUpReservationStatus.cancelled
            case .completed:
                return next == PendingFollowUpReservationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingFollowUpReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending follow up reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("pending follow up reservation") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingFollowUpReservation {
            return PendingFollowUpReservation(
                code: code,
                label: label,
                ownerID: ownerID,
                approved: approved,
                revision: revision,
                createdAt: createdAt,
                facility: facility,
                archived: archived,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending follow up reservation in status planned.
    static func newPendingFollowUpReservation(_ code: String, label: String) -> PendingFollowUpReservation {
        return PendingFollowUpReservation(
            code: code,
            label: label,
            ownerID: "",
            approved: false,
            revision: 0,
            createdAt: 0,
            facility: "",
            archived: false,
            weight: 0.0,
            status: PendingFollowUpReservationStatus.planned
        )
    }
}
