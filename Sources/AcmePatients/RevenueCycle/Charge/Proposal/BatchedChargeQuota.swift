import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched charge quota is in its life cycle.
    enum BatchedChargeQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched charge quota. Its code is unique within a tenant.
    final class BatchedChargeQuota {
        var code: String
        var title: String
        var timezone: String
        var discount: Double
        var source: String
        var status: BatchedChargeQuotaStatus

        init(code: String, title: String, timezone: String, discount: Double, source: String, status: BatchedChargeQuotaStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.discount = discount
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedChargeQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedChargeQuotaStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BatchedChargeQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched charge quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> BatchedChargeQuota {
            return BatchedChargeQuota(
                code: code,
                title: title,
                timezone: timezone,
                discount: discount,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched charge quota in status created.
    static func newBatchedChargeQuota(_ code: String, title: String) -> BatchedChargeQuota {
        return BatchedChargeQuota(
            code: code,
            title: title,
            timezone: "",
            discount: 0.0,
            source: "",
            status: BatchedChargeQuotaStatus.created
        )
    }
}
