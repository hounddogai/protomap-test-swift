import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered referral template is in its life cycle.
    enum TieredReferralTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered referral template. Its code is unique within a tenant.
    final class TieredReferralTemplate {
        var code: String
        var label: String
        var reviewer: String
        var payer: String
        var name: String
        var locale: String
        var summary: String
        var discount: Double
        var status: TieredReferralTemplateStatus

        init(code: String, label: String, reviewer: String, payer: String, name: String, locale: String, summary: String, discount: Double, status: TieredReferralTemplateStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.payer = payer
            self.name = name
            self.locale = locale
            self.summary = summary
            self.discount = discount
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

        func canMoveTo(_ next: TieredReferralTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredReferralTemplateStatus.pending || next == TieredReferralTemplateStatus.active
            case .pending:
                switch next {
                case .active, .closed:
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

        func moveTo(_ next: TieredReferralTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered referral template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> TieredReferralTemplate {
            return TieredReferralTemplate(
                code: code,
                label: label,
                reviewer: reviewer,
                payer: payer,
                name: name,
                locale: locale,
                summary: summary,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a tiered referral template in status draft.
    static func newTieredReferralTemplate(_ code: String, label: String) -> TieredReferralTemplate {
        return TieredReferralTemplate(
            code: code,
            label: label,
            reviewer: "",
            payer: "",
            name: "",
            locale: "",
            summary: "",
            discount: 0.0,
            status: TieredReferralTemplateStatus.draft
        )
    }
}
