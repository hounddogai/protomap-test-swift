import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy proxy template is in its life cycle.
    enum LegacyProxyTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy proxy template. Its code is unique within a tenant.
    final class LegacyProxyTemplate {
        var code: String
        var title: String
        var threshold: Double
        var ward: String
        var category: String
        var currency: String
        var durationMinutes: Int
        var status: LegacyProxyTemplateStatus

        init(code: String, title: String, threshold: Double, ward: String, category: String, currency: String, durationMinutes: Int, status: LegacyProxyTemplateStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.ward = ward
            self.category = category
            self.currency = currency
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: LegacyProxyTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyProxyTemplateStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LegacyProxyTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyProxyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy proxy template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy proxy template") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(durationMinutes) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> LegacyProxyTemplate {
            return LegacyProxyTemplate(
                code: code,
                title: title,
                threshold: threshold,
                ward: ward,
                category: category,
                currency: currency,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy proxy template in status requested.
    static func newLegacyProxyTemplate(_ code: String, title: String) -> LegacyProxyTemplate {
        return LegacyProxyTemplate(
            code: code,
            title: title,
            threshold: 0.0,
            ward: "",
            category: "",
            currency: "",
            durationMinutes: 0,
            status: LegacyProxyTemplateStatus.requested
        )
    }
}
