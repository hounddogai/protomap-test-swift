import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution batch is in its life cycle.
    enum SubstitutionBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A substitution batch as the substitution team keeps it.
    final class SubstitutionBatch {
        var code: String
        var name: String
        var allergy: String
        var durationMinutes: Int
        var encounterID: String
        var batchSize: Int
        var checksum: String
        var discount: Double
        var startsAt: Int
        var status: SubstitutionBatchStatus

        init(code: String, name: String, allergy: String, durationMinutes: Int, encounterID: String, batchSize: Int, checksum: String, discount: Double, startsAt: Int, status: SubstitutionBatchStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.batchSize = batchSize
            self.checksum = checksum
            self.discount = discount
            self.startsAt = startsAt
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

        func canMoveTo(_ next: SubstitutionBatchStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SubstitutionBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return ((Double(batchSize) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionBatch {
            return SubstitutionBatch(
                code: code,
                name: name,
                allergy: allergy,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                batchSize: batchSize,
                checksum: checksum,
                discount: discount,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution batch in status proposed.
    static func newSubstitutionBatch(_ code: String, name: String) -> SubstitutionBatch {
        return SubstitutionBatch(
            code: code,
            name: name,
            allergy: "",
            durationMinutes: 0,
            encounterID: "",
            batchSize: 0,
            checksum: "",
            discount: 0.0,
            startsAt: 0,
            status: SubstitutionBatchStatus.proposed
        )
    }
}
