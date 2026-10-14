import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual rounding checkpoint is in its life cycle.
    enum ManualRoundingCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One manual rounding checkpoint, with what the planners need to act on it.
    final class ManualRoundingCheckpoint {
        var code: String
        var title: String
        var name: String
        var version: Int
        var retries: Int
        var expiresAt: Int
        var clinicianID: String
        var description: String
        var discount: Double
        var specialty: String
        var checksum: String
        var status: ManualRoundingCheckpointStatus

        init(code: String, title: String, name: String, version: Int, retries: Int, expiresAt: Int, clinicianID: String, description: String, discount: Double, specialty: String, checksum: String, status: ManualRoundingCheckpointStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.version = version
            self.retries = retries
            self.expiresAt = expiresAt
            self.clinicianID = clinicianID
            self.description = description
            self.discount = discount
            self.specialty = specialty
            self.checksum = checksum
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

        func canMoveTo(_ next: ManualRoundingCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualRoundingCheckpointStatus.scheduled || next == ManualRoundingCheckpointStatus.cancelled
            case .scheduled:
                return next == ManualRoundingCheckpointStatus.inProgress || next == ManualRoundingCheckpointStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualRoundingCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRoundingCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual rounding checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((discount + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRoundingCheckpoint {
            return ManualRoundingCheckpoint(
                code: code,
                title: title,
                name: name,
                version: version,
                retries: retries,
                expiresAt: expiresAt,
                clinicianID: clinicianID,
                description: description,
                discount: discount,
                specialty: specialty,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual rounding checkpoint in status planned.
    static func newManualRoundingCheckpoint(_ code: String, title: String) -> ManualRoundingCheckpoint {
        return ManualRoundingCheckpoint(
            code: code,
            title: title,
            name: "",
            version: 0,
            retries: 0,
            expiresAt: 0,
            clinicianID: "",
            description: "",
            discount: 0.0,
            specialty: "",
            checksum: "",
            status: ManualRoundingCheckpointStatus.planned
        )
    }
}
