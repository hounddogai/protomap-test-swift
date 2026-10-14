import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding allocation is in its life cycle.
    enum RoundingAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rounding allocation and its current status.
    final class RoundingAllocation {
        var code: String
        var name: String
        var priority: Int
        var expiresAt: Int
        var allergy: String
        var graceDays: Int
        var checksum: String
        var batchSize: Int
        var sequence: Int
        var refills: Int
        var ownerID: String
        var status: RoundingAllocationStatus

        init(code: String, name: String, priority: Int, expiresAt: Int, allergy: String, graceDays: Int, checksum: String, batchSize: Int, sequence: Int, refills: Int, ownerID: String, status: RoundingAllocationStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.graceDays = graceDays
            self.checksum = checksum
            self.batchSize = batchSize
            self.sequence = sequence
            self.refills = refills
            self.ownerID = ownerID
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

        func canMoveTo(_ next: RoundingAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: RoundingAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((Double(expiresAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingAllocation {
            return RoundingAllocation(
                code: code,
                name: name,
                priority: priority,
                expiresAt: expiresAt,
                allergy: allergy,
                graceDays: graceDays,
                checksum: checksum,
                batchSize: batchSize,
                sequence: sequence,
                refills: refills,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding allocation in status proposed.
    static func newRoundingAllocation(_ code: String, name: String) -> RoundingAllocation {
        return RoundingAllocation(
            code: code,
            name: name,
            priority: 0,
            expiresAt: 0,
            allergy: "",
            graceDays: 0,
            checksum: "",
            batchSize: 0,
            sequence: 0,
            refills: 0,
            ownerID: "",
            status: RoundingAllocationStatus.proposed
        )
    }
}
