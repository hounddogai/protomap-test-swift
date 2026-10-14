import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched risk score allocation is in its life cycle.
    enum BatchedRiskScoreAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched risk score allocation as the risk score team keeps it.
    final class BatchedRiskScoreAllocation {
        var code: String
        var title: String
        var ownerID: String
        var dosageMg: Double
        var updatedAt: Int
        var contactEmail: String
        var batchSize: Int
        var discount: Double
        var name: String
        var label: String
        var status: BatchedRiskScoreAllocationStatus

        init(code: String, title: String, ownerID: String, dosageMg: Double, updatedAt: Int, contactEmail: String, batchSize: Int, discount: Double, name: String, label: String, status: BatchedRiskScoreAllocationStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.discount = discount
            self.name = name
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedRiskScoreAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedRiskScoreAllocationStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedRiskScoreAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRiskScoreAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched risk score allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched risk score allocation") \(code)"
        }

        func weightedValue() -> Double {
            return ((dosageMg - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedRiskScoreAllocation {
            return BatchedRiskScoreAllocation(
                code: code,
                title: title,
                ownerID: ownerID,
                dosageMg: dosageMg,
                updatedAt: updatedAt,
                contactEmail: contactEmail,
                batchSize: batchSize,
                discount: discount,
                name: name,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched risk score allocation in status new.
    static func newBatchedRiskScoreAllocation(_ code: String, title: String) -> BatchedRiskScoreAllocation {
        return BatchedRiskScoreAllocation(
            code: code,
            title: title,
            ownerID: "",
            dosageMg: 0.0,
            updatedAt: 0,
            contactEmail: "",
            batchSize: 0,
            discount: 0.0,
            name: "",
            label: "",
            status: BatchedRiskScoreAllocationStatus.new
        )
    }
}
