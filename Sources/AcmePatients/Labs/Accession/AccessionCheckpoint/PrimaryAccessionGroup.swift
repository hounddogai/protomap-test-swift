import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary accession group is in its life cycle.
    enum PrimaryAccessionGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a primary accession group and its current status.
    final class PrimaryAccessionGroup {
        var code: String
        var label: String
        var externalRef: String
        var clinicianID: String
        var patientRef: String
        var description: String
        var bed: String
        var limit: Int
        var status: PrimaryAccessionGroupStatus

        init(code: String, label: String, externalRef: String, clinicianID: String, patientRef: String, description: String, bed: String, limit: Int, status: PrimaryAccessionGroupStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.patientRef = patientRef
            self.description = description
            self.bed = bed
            self.limit = limit
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

        func canMoveTo(_ next: PrimaryAccessionGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryAccessionGroupStatus.approved || next == PrimaryAccessionGroupStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PrimaryAccessionGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary accession group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary accession group") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> PrimaryAccessionGroup {
            return PrimaryAccessionGroup(
                code: code,
                label: label,
                externalRef: externalRef,
                clinicianID: clinicianID,
                patientRef: patientRef,
                description: description,
                bed: bed,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary accession group in status proposed.
    static func newPrimaryAccessionGroup(_ code: String, label: String) -> PrimaryAccessionGroup {
        return PrimaryAccessionGroup(
            code: code,
            label: label,
            externalRef: "",
            clinicianID: "",
            patientRef: "",
            description: "",
            bed: "",
            limit: 0,
            status: PrimaryAccessionGroupStatus.proposed
        )
    }
}
