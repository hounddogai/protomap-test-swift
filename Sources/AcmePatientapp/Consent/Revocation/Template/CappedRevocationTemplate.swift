import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped revocation template is in its life cycle.
    enum CappedRevocationTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped revocation template. Its code is unique within a tenant.
    final class CappedRevocationTemplate {
        var code: String
        var title: String
        var timezone: String
        var cost: Double
        var discount: Double
        var active: Bool
        var status: CappedRevocationTemplateStatus

        init(code: String, title: String, timezone: String, cost: Double, discount: Double, active: Bool, status: CappedRevocationTemplateStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.cost = cost
            self.discount = discount
            self.active = active
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

        func canMoveTo(_ next: CappedRevocationTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedRevocationTemplateStatus.reopened || next == CappedRevocationTemplateStatus.archived
            case .reopened:
                return next == CappedRevocationTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRevocationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped revocation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return ((discount + cost) * 100).rounded() / 100
        }

        func copyValue() -> CappedRevocationTemplate {
            return CappedRevocationTemplate(
                code: code,
                title: title,
                timezone: timezone,
                cost: cost,
                discount: discount,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped revocation template in status open.
    static func newCappedRevocationTemplate(_ code: String, title: String) -> CappedRevocationTemplate {
        return CappedRevocationTemplate(
            code: code,
            title: title,
            timezone: "",
            cost: 0.0,
            discount: 0.0,
            active: false,
            status: CappedRevocationTemplateStatus.`open`
        )
    }
}
