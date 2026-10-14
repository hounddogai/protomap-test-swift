import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered language template is in its life cycle.
    enum TieredLanguageTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered language template as the language team keeps it.
    final class TieredLanguageTemplate {
        var code: String
        var title: String
        var score: Double
        var weight: Double
        var ratio: Double
        var discount: Double
        var updatedAt: Int
        var status: TieredLanguageTemplateStatus

        init(code: String, title: String, score: Double, weight: Double, ratio: Double, discount: Double, updatedAt: Int, status: TieredLanguageTemplateStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.weight = weight
            self.ratio = ratio
            self.discount = discount
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: TieredLanguageTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredLanguageTemplateStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredLanguageTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredLanguageTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered language template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((weight + score) * 100).rounded() / 100
        }

        func copyValue() -> TieredLanguageTemplate {
            return TieredLanguageTemplate(
                code: code,
                title: title,
                score: score,
                weight: weight,
                ratio: ratio,
                discount: discount,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered language template in status requested.
    static func newTieredLanguageTemplate(_ code: String, title: String) -> TieredLanguageTemplate {
        return TieredLanguageTemplate(
            code: code,
            title: title,
            score: 0.0,
            weight: 0.0,
            ratio: 0.0,
            discount: 0.0,
            updatedAt: 0,
            status: TieredLanguageTemplateStatus.requested
        )
    }
}
