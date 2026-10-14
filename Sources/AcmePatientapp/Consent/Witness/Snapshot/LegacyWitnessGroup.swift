import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy witness group is in its life cycle.
    enum LegacyWitnessGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy witness group and its current status.
    final class LegacyWitnessGroup {
        var code: String
        var title: String
        var procedureCode: String
        var patientRef: String
        var floorValue: Double
        var approved: Bool
        var ownerID: String
        var contactEmail: String
        var unit: String
        var encounterID: String
        var status: LegacyWitnessGroupStatus

        init(code: String, title: String, procedureCode: String, patientRef: String, floorValue: Double, approved: Bool, ownerID: String, contactEmail: String, unit: String, encounterID: String, status: LegacyWitnessGroupStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.approved = approved
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.unit = unit
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LegacyWitnessGroupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LegacyWitnessGroupStatus.suspended || next == LegacyWitnessGroupStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyWitnessGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy witness group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> LegacyWitnessGroup {
            return LegacyWitnessGroup(
                code: code,
                title: title,
                procedureCode: procedureCode,
                patientRef: patientRef,
                floorValue: floorValue,
                approved: approved,
                ownerID: ownerID,
                contactEmail: contactEmail,
                unit: unit,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy witness group in status draft.
    static func newLegacyWitnessGroup(_ code: String, title: String) -> LegacyWitnessGroup {
        return LegacyWitnessGroup(
            code: code,
            title: title,
            procedureCode: "",
            patientRef: "",
            floorValue: 0.0,
            approved: false,
            ownerID: "",
            contactEmail: "",
            unit: "",
            encounterID: "",
            status: LegacyWitnessGroupStatus.draft
        )
    }
}
