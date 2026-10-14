import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary variance is in its life cycle.
    enum FormularyVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A formulary variance as the formulary team keeps it.
    final class FormularyVariance {
        var code: String
        var title: String
        var category: String
        var margin: Double
        var label: String
        var visible: Bool
        var status: FormularyVarianceStatus

        init(code: String, title: String, category: String, margin: Double, label: String, visible: Bool, status: FormularyVarianceStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.margin = margin
            self.label = label
            self.visible = visible
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

        func canMoveTo(_ next: FormularyVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FormularyVarianceStatus.revoked || next == FormularyVarianceStatus.expired
            case .revoked:
                return next == FormularyVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> FormularyVariance {
            return FormularyVariance(
                code: code,
                title: title,
                category: category,
                margin: margin,
                label: label,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a formulary variance in status requested.
    static func newFormularyVariance(_ code: String, title: String) -> FormularyVariance {
        return FormularyVariance(
            code: code,
            title: title,
            category: "",
            margin: 0.0,
            label: "",
            visible: false,
            status: FormularyVarianceStatus.requested
        )
    }
}
