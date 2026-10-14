import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive language template is in its life cycle.
    enum AdaptiveLanguageTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive language template as the language team keeps it.
    final class AdaptiveLanguageTemplate {
        var code: String
        var title: String
        var notes: String
        var dosageMg: Double
        var amount: Double
        var windowDays: Int
        var status: AdaptiveLanguageTemplateStatus

        init(code: String, title: String, notes: String, dosageMg: Double, amount: Double, windowDays: Int, status: AdaptiveLanguageTemplateStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.dosageMg = dosageMg
            self.amount = amount
            self.windowDays = windowDays
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

        func canMoveTo(_ next: AdaptiveLanguageTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveLanguageTemplateStatus.revoked || next == AdaptiveLanguageTemplateStatus.expired
            case .revoked:
                return next == AdaptiveLanguageTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveLanguageTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive language template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return (dosageMg * amount * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveLanguageTemplate {
            return AdaptiveLanguageTemplate(
                code: code,
                title: title,
                notes: notes,
                dosageMg: dosageMg,
                amount: amount,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive language template in status requested.
    static func newAdaptiveLanguageTemplate(_ code: String, title: String) -> AdaptiveLanguageTemplate {
        return AdaptiveLanguageTemplate(
            code: code,
            title: title,
            notes: "",
            dosageMg: 0.0,
            amount: 0.0,
            windowDays: 0,
            status: AdaptiveLanguageTemplateStatus.requested
        )
    }
}
