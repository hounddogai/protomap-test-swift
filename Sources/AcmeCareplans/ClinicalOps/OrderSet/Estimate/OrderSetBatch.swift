import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set batch is in its life cycle.
    enum OrderSetBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a order set batch and its current status.
    final class OrderSetBatch {
        var code: String
        var name: String
        var bed: String
        var copay: Double
        var clinicianID: String
        var allergy: String
        var status: OrderSetBatchStatus

        init(code: String, name: String, bed: String, copay: Double, clinicianID: String, allergy: String, status: OrderSetBatchStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.copay = copay
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OrderSetBatchStatus.inReview || next == OrderSetBatchStatus.resolved
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == OrderSetBatchStatus.reopened || next == OrderSetBatchStatus.archived
            case .reopened:
                return next == OrderSetBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> OrderSetBatch {
            return OrderSetBatch(
                code: code,
                name: name,
                bed: bed,
                copay: copay,
                clinicianID: clinicianID,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set batch in status open.
    static func newOrderSetBatch(_ code: String, name: String) -> OrderSetBatch {
        return OrderSetBatch(
            code: code,
            name: name,
            bed: "",
            copay: 0.0,
            clinicianID: "",
            allergy: "",
            status: OrderSetBatchStatus.`open`
        )
    }
}
