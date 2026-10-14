import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness quota is in its life cycle.
    enum BatchedWitnessQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched witness quota. Its code is unique within a tenant.
    final class BatchedWitnessQuota {
        var code: String
        var name: String
        var acuity: Int
        var ownerID: String
        var allergy: String
        var status: BatchedWitnessQuotaStatus

        init(code: String, name: String, acuity: Int, ownerID: String, allergy: String, status: BatchedWitnessQuotaStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.ownerID = ownerID
            self.allergy = allergy
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

        func canMoveTo(_ next: BatchedWitnessQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedWitnessQuotaStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedWitnessQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched witness quota") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> BatchedWitnessQuota {
            return BatchedWitnessQuota(
                code: code,
                name: name,
                acuity: acuity,
                ownerID: ownerID,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched witness quota in status draft.
    static func newBatchedWitnessQuota(_ code: String, name: String) -> BatchedWitnessQuota {
        return BatchedWitnessQuota(
            code: code,
            name: name,
            acuity: 0,
            ownerID: "",
            allergy: "",
            status: BatchedWitnessQuotaStatus.draft
        )
    }
}
