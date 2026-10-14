import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution record is in its life cycle.
    enum SubstitutionRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A substitution record as the substitution team keeps it.
    final class SubstitutionRecord {
        var code: String
        var name: String
        var acuity: Int
        var notes: String
        var discount: Double
        var facility: String
        var attempts: Int
        var capacity: Int
        var archived: Bool
        var copay: Double
        var encounterID: String
        var status: SubstitutionRecordStatus

        init(code: String, name: String, acuity: Int, notes: String, discount: Double, facility: String, attempts: Int, capacity: Int, archived: Bool, copay: Double, encounterID: String, status: SubstitutionRecordStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.notes = notes
            self.discount = discount
            self.facility = facility
            self.attempts = attempts
            self.capacity = capacity
            self.archived = archived
            self.copay = copay
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SubstitutionRecordStatus) -> Bool {
            switch status {
            case .requested:
                return next == SubstitutionRecordStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == SubstitutionRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("substitution record") \(code)"
        }

        func adjustedLoad() -> Double {
            return (copay * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionRecord {
            return SubstitutionRecord(
                code: code,
                name: name,
                acuity: acuity,
                notes: notes,
                discount: discount,
                facility: facility,
                attempts: attempts,
                capacity: capacity,
                archived: archived,
                copay: copay,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a substitution record in status requested.
    static func newSubstitutionRecord(_ code: String, name: String) -> SubstitutionRecord {
        return SubstitutionRecord(
            code: code,
            name: name,
            acuity: 0,
            notes: "",
            discount: 0.0,
            facility: "",
            attempts: 0,
            capacity: 0,
            archived: false,
            copay: 0.0,
            encounterID: "",
            status: SubstitutionRecordStatus.requested
        )
    }
}
