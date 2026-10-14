import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board rollup is in its life cycle.
    enum BedBoardRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One bed board rollup, with what the planners need to act on it.
    final class BedBoardRollup {
        var code: String
        var label: String
        var checksum: String
        var clinicianID: String
        var procedureCode: String
        var bed: String
        var facility: String
        var diagnosisCode: String
        var expiresAt: Int
        var payer: String
        var notes: String
        var status: BedBoardRollupStatus

        init(code: String, label: String, checksum: String, clinicianID: String, procedureCode: String, bed: String, facility: String, diagnosisCode: String, expiresAt: Int, payer: String, notes: String, status: BedBoardRollupStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.procedureCode = procedureCode
            self.bed = bed
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.payer = payer
            self.notes = notes
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

        func canMoveTo(_ next: BedBoardRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == BedBoardRollupStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == BedBoardRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> BedBoardRollup {
            return BedBoardRollup(
                code: code,
                label: label,
                checksum: checksum,
                clinicianID: clinicianID,
                procedureCode: procedureCode,
                bed: bed,
                facility: facility,
                diagnosisCode: diagnosisCode,
                expiresAt: expiresAt,
                payer: payer,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a bed board rollup in status draft.
    static func newBedBoardRollup(_ code: String, label: String) -> BedBoardRollup {
        return BedBoardRollup(
            code: code,
            label: label,
            checksum: "",
            clinicianID: "",
            procedureCode: "",
            bed: "",
            facility: "",
            diagnosisCode: "",
            expiresAt: 0,
            payer: "",
            notes: "",
            status: BedBoardRollupStatus.draft
        )
    }
}
