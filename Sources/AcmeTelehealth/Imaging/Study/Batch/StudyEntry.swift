import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study entry is in its life cycle.
    enum StudyEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A study entry as the study team keeps it.
    final class StudyEntry {
        var code: String
        var title: String
        var name: String
        var pinned: Bool
        var minimum: Double
        var encounterID: String
        var specialty: String
        var procedureCode: String
        var clinicianID: String
        var visible: Bool
        var summary: String
        var status: StudyEntryStatus

        init(code: String, title: String, name: String, pinned: Bool, minimum: Double, encounterID: String, specialty: String, procedureCode: String, clinicianID: String, visible: Bool, summary: String, status: StudyEntryStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.pinned = pinned
            self.minimum = minimum
            self.encounterID = encounterID
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.clinicianID = clinicianID
            self.visible = visible
            self.summary = summary
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

        func canMoveTo(_ next: StudyEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StudyEntryStatus.approved
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StudyEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> StudyEntry {
            return StudyEntry(
                code: code,
                title: title,
                name: name,
                pinned: pinned,
                minimum: minimum,
                encounterID: encounterID,
                specialty: specialty,
                procedureCode: procedureCode,
                clinicianID: clinicianID,
                visible: visible,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a study entry in status proposed.
    static func newStudyEntry(_ code: String, title: String) -> StudyEntry {
        return StudyEntry(
            code: code,
            title: title,
            name: "",
            pinned: false,
            minimum: 0.0,
            encounterID: "",
            specialty: "",
            procedureCode: "",
            clinicianID: "",
            visible: false,
            summary: "",
            status: StudyEntryStatus.proposed
        )
    }
}
