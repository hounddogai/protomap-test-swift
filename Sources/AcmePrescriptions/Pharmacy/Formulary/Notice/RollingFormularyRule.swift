import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling formulary rule is in its life cycle.
    enum RollingFormularyRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling formulary rule. Its code is unique within a tenant.
    final class RollingFormularyRule {
        var code: String
        var name: String
        var limit: Int
        var dosageMg: Double
        var externalRef: String
        var status: RollingFormularyRuleStatus

        init(code: String, name: String, limit: Int, dosageMg: Double, externalRef: String, status: RollingFormularyRuleStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.dosageMg = dosageMg
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingFormularyRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RollingFormularyRuleStatus.retired
            case .published:
                return next == RollingFormularyRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingFormularyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling formulary rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> RollingFormularyRule {
            return RollingFormularyRule(
                code: code,
                name: name,
                limit: limit,
                dosageMg: dosageMg,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling formulary rule in status created.
    static func newRollingFormularyRule(_ code: String, name: String) -> RollingFormularyRule {
        return RollingFormularyRule(
            code: code,
            name: name,
            limit: 0,
            dosageMg: 0.0,
            externalRef: "",
            status: RollingFormularyRuleStatus.created
        )
    }
}
