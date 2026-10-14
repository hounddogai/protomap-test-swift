import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim template is in its life cycle.
    enum LenientClaimTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient claim template. Its code is unique within a tenant.
    final class LenientClaimTemplate {
        var code: String
        var name: String
        var locale: String
        var region: String
        var summary: String
        var amount: Double
        var status: LenientClaimTemplateStatus

        init(code: String, name: String, locale: String, region: String, summary: String, amount: Double, status: LenientClaimTemplateStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.region = region
            self.summary = summary
            self.amount = amount
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

        func canMoveTo(_ next: LenientClaimTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientClaimTemplateStatus.reopened || next == LenientClaimTemplateStatus.archived
            case .resolved:
                return next == LenientClaimTemplateStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LenientClaimTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> LenientClaimTemplate {
            return LenientClaimTemplate(
                code: code,
                name: name,
                locale: locale,
                region: region,
                summary: summary,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient claim template in status open.
    static func newLenientClaimTemplate(_ code: String, name: String) -> LenientClaimTemplate {
        return LenientClaimTemplate(
            code: code,
            name: name,
            locale: "",
            region: "",
            summary: "",
            amount: 0.0,
            status: LenientClaimTemplateStatus.`open`
        )
    }
}
