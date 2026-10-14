import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive remittance quota is in its life cycle.
    enum AdaptiveRemittanceQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive remittance quota as the remittance team keeps it.
    final class AdaptiveRemittanceQuota {
        var code: String
        var label: String
        var segment: String
        var revision: Int
        var maximum: Double
        var startsAt: Int
        var amount: Double
        var weight: Double
        var ratio: Double
        var ward: String
        var category: String
        var status: AdaptiveRemittanceQuotaStatus

        init(code: String, label: String, segment: String, revision: Int, maximum: Double, startsAt: Int, amount: Double, weight: Double, ratio: Double, ward: String, category: String, status: AdaptiveRemittanceQuotaStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.revision = revision
            self.maximum = maximum
            self.startsAt = startsAt
            self.amount = amount
            self.weight = weight
            self.ratio = ratio
            self.ward = ward
            self.category = category
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

        func canMoveTo(_ next: AdaptiveRemittanceQuotaStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveRemittanceQuotaStatus.revoked || next == AdaptiveRemittanceQuotaStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptiveRemittanceQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive remittance quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("adaptive remittance quota") \(code)"
        }

        func weightedLoad() -> Double {
            return (amount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRemittanceQuota {
            return AdaptiveRemittanceQuota(
                code: code,
                label: label,
                segment: segment,
                revision: revision,
                maximum: maximum,
                startsAt: startsAt,
                amount: amount,
                weight: weight,
                ratio: ratio,
                ward: ward,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive remittance quota in status requested.
    static func newAdaptiveRemittanceQuota(_ code: String, label: String) -> AdaptiveRemittanceQuota {
        return AdaptiveRemittanceQuota(
            code: code,
            label: label,
            segment: "",
            revision: 0,
            maximum: 0.0,
            startsAt: 0,
            amount: 0.0,
            weight: 0.0,
            ratio: 0.0,
            ward: "",
            category: "",
            status: AdaptiveRemittanceQuotaStatus.requested
        )
    }
}
