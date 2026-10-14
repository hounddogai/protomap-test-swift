import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary template is in its life cycle.
    enum FormularyTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One formulary template, with what the planners need to act on it.
    final class FormularyTemplate {
        var code: String
        var title: String
        var allergy: String
        var diagnosisCode: String
        var category: String
        var graceDays: Int
        var visible: Bool
        var status: FormularyTemplateStatus

        init(code: String, title: String, allergy: String, diagnosisCode: String, category: String, graceDays: Int, visible: Bool, status: FormularyTemplateStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.graceDays = graceDays
            self.visible = visible
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

        func canMoveTo(_ next: FormularyTemplateStatus) -> Bool {
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
                return next == FormularyTemplateStatus.withdrawn
            case .rejected:
                return next == FormularyTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> FormularyTemplate {
            return FormularyTemplate(
                code: code,
                title: title,
                allergy: allergy,
                diagnosisCode: diagnosisCode,
                category: category,
                graceDays: graceDays,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a formulary template in status proposed.
    static func newFormularyTemplate(_ code: String, title: String) -> FormularyTemplate {
        return FormularyTemplate(
            code: code,
            title: title,
            allergy: "",
            diagnosisCode: "",
            category: "",
            graceDays: 0,
            visible: false,
            status: FormularyTemplateStatus.proposed
        )
    }
}
