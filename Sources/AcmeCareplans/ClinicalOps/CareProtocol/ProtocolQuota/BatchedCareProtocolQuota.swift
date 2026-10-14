import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched care protocol quota is in its life cycle.
    enum BatchedCareProtocolQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched care protocol quota. Its code is unique within a tenant.
    final class BatchedCareProtocolQuota {
        var code: String
        var label: String
        var priority: Int
        var durationMinutes: Int
        var category: String
        var status: BatchedCareProtocolQuotaStatus

        init(code: String, label: String, priority: Int, durationMinutes: Int, category: String, status: BatchedCareProtocolQuotaStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.category = category
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

        func canMoveTo(_ next: BatchedCareProtocolQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedCareProtocolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care protocol quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(priority) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareProtocolQuota {
            return BatchedCareProtocolQuota(
                code: code,
                label: label,
                priority: priority,
                durationMinutes: durationMinutes,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched care protocol quota in status proposed.
    static func newBatchedCareProtocolQuota(_ code: String, label: String) -> BatchedCareProtocolQuota {
        return BatchedCareProtocolQuota(
            code: code,
            label: label,
            priority: 0,
            durationMinutes: 0,
            category: "",
            status: BatchedCareProtocolQuotaStatus.proposed
        )
    }
}
