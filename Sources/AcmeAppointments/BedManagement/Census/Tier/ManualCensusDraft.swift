import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual census draft is in its life cycle.
    enum ManualCensusDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual census draft as the census team keeps it.
    final class ManualCensusDraft {
        var code: String
        var label: String
        var notes: String
        var encounterID: String
        var description: String
        var retries: Int
        var clinicianID: String
        var status: ManualCensusDraftStatus

        init(code: String, label: String, notes: String, encounterID: String, description: String, retries: Int, clinicianID: String, status: ManualCensusDraftStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.encounterID = encounterID
            self.description = description
            self.retries = retries
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualCensusDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ManualCensusDraftStatus.published
            case .published:
                return next == ManualCensusDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCensusDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual census draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> ManualCensusDraft {
            return ManualCensusDraft(
                code: code,
                label: label,
                notes: notes,
                encounterID: encounterID,
                description: description,
                retries: retries,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual census draft in status created.
    static func newManualCensusDraft(_ code: String, label: String) -> ManualCensusDraft {
        return ManualCensusDraft(
            code: code,
            label: label,
            notes: "",
            encounterID: "",
            description: "",
            retries: 0,
            clinicianID: "",
            status: ManualCensusDraftStatus.created
        )
    }
}
