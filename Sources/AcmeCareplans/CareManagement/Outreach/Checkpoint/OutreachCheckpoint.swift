import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach checkpoint is in its life cycle.
    enum OutreachCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A outreach checkpoint as the outreach team keeps it.
    final class OutreachCheckpoint {
        var code: String
        var label: String
        var archived: Bool
        var capacity: Int
        var notes: String
        var contactEmail: String
        var ownerID: String
        var threshold: Double
        var status: OutreachCheckpointStatus

        init(code: String, label: String, archived: Bool, capacity: Int, notes: String, contactEmail: String, ownerID: String, threshold: Double, status: OutreachCheckpointStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.capacity = capacity
            self.notes = notes
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.threshold = threshold
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

        func canMoveTo(_ next: OutreachCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == OutreachCheckpointStatus.warming
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == OutreachCheckpointStatus.draining || next == OutreachCheckpointStatus.stopped
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

        func moveTo(_ next: OutreachCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("outreach checkpoint") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((threshold + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachCheckpoint {
            return OutreachCheckpoint(
                code: code,
                label: label,
                archived: archived,
                capacity: capacity,
                notes: notes,
                contactEmail: contactEmail,
                ownerID: ownerID,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a outreach checkpoint in status idle.
    static func newOutreachCheckpoint(_ code: String, label: String) -> OutreachCheckpoint {
        return OutreachCheckpoint(
            code: code,
            label: label,
            archived: false,
            capacity: 0,
            notes: "",
            contactEmail: "",
            ownerID: "",
            threshold: 0.0,
            status: OutreachCheckpointStatus.idle
        )
    }
}
