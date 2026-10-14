import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback referral audit is in its life cycle.
    enum FallbackReferralAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback referral audit. Its code is unique within a tenant.
    final class FallbackReferralAudit {
        var code: String
        var label: String
        var margin: Double
        var batchSize: Int
        var country: String
        var category: String
        var status: FallbackReferralAuditStatus

        init(code: String, label: String, margin: Double, batchSize: Int, country: String, category: String, status: FallbackReferralAuditStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.batchSize = batchSize
            self.country = country
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

        func canMoveTo(_ next: FallbackReferralAuditStatus) -> Bool {
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
                return next == FallbackReferralAuditStatus.rejected || next == FallbackReferralAuditStatus.withdrawn
            case .rejected:
                return next == FallbackReferralAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackReferralAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback referral audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) + margin) * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferralAudit {
            return FallbackReferralAudit(
                code: code,
                label: label,
                margin: margin,
                batchSize: batchSize,
                country: country,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback referral audit in status proposed.
    static func newFallbackReferralAudit(_ code: String, label: String) -> FallbackReferralAudit {
        return FallbackReferralAudit(
            code: code,
            label: label,
            margin: 0.0,
            batchSize: 0,
            country: "",
            category: "",
            status: FallbackReferralAuditStatus.proposed
        )
    }
}
