import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional accession checkpoint is in its life cycle.
    enum RegionalAccessionCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional accession checkpoint and its current status.
    final class RegionalAccessionCheckpoint {
        var code: String
        var name: String
        var encounterID: String
        var title: String
        var specialty: String
        var summary: String
        var ownerID: String
        var priority: Int
        var acuity: Int
        var durationMinutes: Int
        var attempts: Int
        var status: RegionalAccessionCheckpointStatus

        init(code: String, name: String, encounterID: String, title: String, specialty: String, summary: String, ownerID: String, priority: Int, acuity: Int, durationMinutes: Int, attempts: Int, status: RegionalAccessionCheckpointStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.title = title
            self.specialty = specialty
            self.summary = summary
            self.ownerID = ownerID
            self.priority = priority
            self.acuity = acuity
            self.durationMinutes = durationMinutes
            self.attempts = attempts
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

        func canMoveTo(_ next: RegionalAccessionCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalAccessionCheckpointStatus.scheduled || next == RegionalAccessionCheckpointStatus.cancelled
            case .scheduled:
                return next == RegionalAccessionCheckpointStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalAccessionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional accession checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(acuity) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAccessionCheckpoint {
            return RegionalAccessionCheckpoint(
                code: code,
                name: name,
                encounterID: encounterID,
                title: title,
                specialty: specialty,
                summary: summary,
                ownerID: ownerID,
                priority: priority,
                acuity: acuity,
                durationMinutes: durationMinutes,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional accession checkpoint in status planned.
    static func newRegionalAccessionCheckpoint(_ code: String, name: String) -> RegionalAccessionCheckpoint {
        return RegionalAccessionCheckpoint(
            code: code,
            name: name,
            encounterID: "",
            title: "",
            specialty: "",
            summary: "",
            ownerID: "",
            priority: 0,
            acuity: 0,
            durationMinutes: 0,
            attempts: 0,
            status: RegionalAccessionCheckpointStatus.planned
        )
    }
}
