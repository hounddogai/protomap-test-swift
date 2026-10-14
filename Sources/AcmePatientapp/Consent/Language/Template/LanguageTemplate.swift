import AcmePlatform
import Foundation

extension Consent {
    /// Where a language template is in its life cycle.
    enum LanguageTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A language template as the language team keeps it.
    final class LanguageTemplate {
        var code: String
        var title: String
        var quantity: Int
        var allergy: String
        var category: String
        var status: LanguageTemplateStatus

        init(code: String, title: String, quantity: Int, allergy: String, category: String, status: LanguageTemplateStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.allergy = allergy
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

        func canMoveTo(_ next: LanguageTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == LanguageTemplateStatus.granted || next == LanguageTemplateStatus.expired
            case .granted:
                return next == LanguageTemplateStatus.revoked
            case .revoked:
                return next == LanguageTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language template") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> LanguageTemplate {
            return LanguageTemplate(
                code: code,
                title: title,
                quantity: quantity,
                allergy: allergy,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a language template in status requested.
    static func newLanguageTemplate(_ code: String, title: String) -> LanguageTemplate {
        return LanguageTemplate(
            code: code,
            title: title,
            quantity: 0,
            allergy: "",
            category: "",
            status: LanguageTemplateStatus.requested
        )
    }
}
