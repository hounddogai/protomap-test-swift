import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered charge quota is in its life cycle.
    enum TieredChargeQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered charge quota. Its code is unique within a tenant.
    final class TieredChargeQuota {
        var code: String
        var label: String
        var procedureCode: String
        var contactEmail: String
        var rate: Double
        var discount: Double
        var ceiling: Double
        var visitMinutes: Int
        var status: TieredChargeQuotaStatus

        init(code: String, label: String, procedureCode: String, contactEmail: String, rate: Double, discount: Double, ceiling: Double, visitMinutes: Int, status: TieredChargeQuotaStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.rate = rate
            self.discount = discount
            self.ceiling = ceiling
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: TieredChargeQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredChargeQuotaStatus.retired
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredChargeQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered charge quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered charge quota") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(visitMinutes) + discount) * 100).rounded() / 100
        }

        func copyValue() -> TieredChargeQuota {
            return TieredChargeQuota(
                code: code,
                label: label,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                rate: rate,
                discount: discount,
                ceiling: ceiling,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered charge quota in status created.
    static func newTieredChargeQuota(_ code: String, label: String) -> TieredChargeQuota {
        return TieredChargeQuota(
            code: code,
            label: label,
            procedureCode: "",
            contactEmail: "",
            rate: 0.0,
            discount: 0.0,
            ceiling: 0.0,
            visitMinutes: 0,
            status: TieredChargeQuotaStatus.created
        )
    }
}
