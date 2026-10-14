import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program group is in its life cycle.
    enum ProgramGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One program group, with what the planners need to act on it.
    final class ProgramGroup {
        var code: String
        var label: String
        var encounterID: String
        var reviewer: String
        var specialty: String
        var copay: Double
        var contactEmail: String
        var margin: Double
        var clinicianID: String
        var ownerID: String
        var notes: String
        var status: ProgramGroupStatus

        init(code: String, label: String, encounterID: String, reviewer: String, specialty: String, copay: Double, contactEmail: String, margin: Double, clinicianID: String, ownerID: String, notes: String, status: ProgramGroupStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.specialty = specialty
            self.copay = copay
            self.contactEmail = contactEmail
            self.margin = margin
            self.clinicianID = clinicianID
            self.ownerID = ownerID
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ProgramGroupStatus.revoked || next == ProgramGroupStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ProgramGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("program group") \(code)"
        }

        func netVolume() -> Double {
            return ((copay - margin) * 100).rounded() / 100
        }

        func copyValue() -> ProgramGroup {
            return ProgramGroup(
                code: code,
                label: label,
                encounterID: encounterID,
                reviewer: reviewer,
                specialty: specialty,
                copay: copay,
                contactEmail: contactEmail,
                margin: margin,
                clinicianID: clinicianID,
                ownerID: ownerID,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a program group in status requested.
    static func newProgramGroup(_ code: String, label: String) -> ProgramGroup {
        return ProgramGroup(
            code: code,
            label: label,
            encounterID: "",
            reviewer: "",
            specialty: "",
            copay: 0.0,
            contactEmail: "",
            margin: 0.0,
            clinicianID: "",
            ownerID: "",
            notes: "",
            status: ProgramGroupStatus.requested
        )
    }
}
