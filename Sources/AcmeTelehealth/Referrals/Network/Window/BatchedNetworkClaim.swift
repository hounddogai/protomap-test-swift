import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched network claim is in its life cycle.
    enum BatchedNetworkClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched network claim and its current status.
    final class BatchedNetworkClaim {
        var code: String
        var label: String
        var checksum: String
        var budget: Double
        var encounterID: String
        var phone: String
        var unit: String
        var specialty: String
        var bed: String
        var status: BatchedNetworkClaimStatus

        init(code: String, label: String, checksum: String, budget: Double, encounterID: String, phone: String, unit: String, specialty: String, bed: String, status: BatchedNetworkClaimStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.budget = budget
            self.encounterID = encounterID
            self.phone = phone
            self.unit = unit
            self.specialty = specialty
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedNetworkClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedNetworkClaimStatus.warming || next == BatchedNetworkClaimStatus.ready
            case .warming:
                return next == BatchedNetworkClaimStatus.ready
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedNetworkClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched network claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> BatchedNetworkClaim {
            return BatchedNetworkClaim(
                code: code,
                label: label,
                checksum: checksum,
                budget: budget,
                encounterID: encounterID,
                phone: phone,
                unit: unit,
                specialty: specialty,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched network claim in status idle.
    static func newBatchedNetworkClaim(_ code: String, label: String) -> BatchedNetworkClaim {
        return BatchedNetworkClaim(
            code: code,
            label: label,
            checksum: "",
            budget: 0.0,
            encounterID: "",
            phone: "",
            unit: "",
            specialty: "",
            bed: "",
            status: BatchedNetworkClaimStatus.idle
        )
    }
}
