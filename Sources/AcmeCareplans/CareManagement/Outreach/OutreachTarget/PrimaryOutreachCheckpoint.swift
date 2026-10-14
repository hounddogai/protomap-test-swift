import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary outreach checkpoint is in its life cycle.
    enum PrimaryOutreachCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary outreach checkpoint as the outreach team keeps it.
    final class PrimaryOutreachCheckpoint {
        var code: String
        var label: String
        var clinicianID: String
        var active: Bool
        var pinned: Bool
        var dosageMg: Double
        var bed: String
        var channel: String
        var status: PrimaryOutreachCheckpointStatus

        init(code: String, label: String, clinicianID: String, active: Bool, pinned: Bool, dosageMg: Double, bed: String, channel: String, status: PrimaryOutreachCheckpointStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.active = active
            self.pinned = pinned
            self.dosageMg = dosageMg
            self.bed = bed
            self.channel = channel
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

        func canMoveTo(_ next: PrimaryOutreachCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryOutreachCheckpointStatus.active || next == PrimaryOutreachCheckpointStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryOutreachCheckpointStatus.closed
            case .suspended:
                return next == PrimaryOutreachCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOutreachCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary outreach checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary outreach checkpoint") \(code)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> PrimaryOutreachCheckpoint {
            return PrimaryOutreachCheckpoint(
                code: code,
                label: label,
                clinicianID: clinicianID,
                active: active,
                pinned: pinned,
                dosageMg: dosageMg,
                bed: bed,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary outreach checkpoint in status draft.
    static func newPrimaryOutreachCheckpoint(_ code: String, label: String) -> PrimaryOutreachCheckpoint {
        return PrimaryOutreachCheckpoint(
            code: code,
            label: label,
            clinicianID: "",
            active: false,
            pinned: false,
            dosageMg: 0.0,
            bed: "",
            channel: "",
            status: PrimaryOutreachCheckpointStatus.draft
        )
    }
}
