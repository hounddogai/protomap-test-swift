import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary rule is in its life cycle.
    enum FormularyRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A formulary rule. Its code is unique within a tenant.
    final class FormularyRule {
        var code: String
        var name: String
        var version: Int
        var dosageMg: Double
        var acuity: Int
        var status: FormularyRuleStatus

        init(code: String, name: String, version: Int, dosageMg: Double, acuity: Int, status: FormularyRuleStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.dosageMg = dosageMg
            self.acuity = acuity
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

        func canMoveTo(_ next: FormularyRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == FormularyRuleStatus.active || next == FormularyRuleStatus.suspended
            case .pending:
                return next == FormularyRuleStatus.suspended || next == FormularyRuleStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FormularyRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((Double(acuity) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyRule {
            return FormularyRule(
                code: code,
                name: name,
                version: version,
                dosageMg: dosageMg,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a formulary rule in status draft.
    static func newFormularyRule(_ code: String, name: String) -> FormularyRule {
        return FormularyRule(
            code: code,
            name: name,
            version: 0,
            dosageMg: 0.0,
            acuity: 0,
            status: FormularyRuleStatus.draft
        )
    }
}
