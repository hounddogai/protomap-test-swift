import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling substitution rule is in its life cycle.
    enum RollingSubstitutionRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rolling substitution rule and its current status.
    final class RollingSubstitutionRule {
        var code: String
        var name: String
        var procedureCode: String
        var updatedAt: Int
        var specialty: String
        var maximum: Double
        var attributes: [String: String]
        var graceDays: Int
        var payer: String
        var phone: String
        var source: String
        var status: RollingSubstitutionRuleStatus

        init(code: String, name: String, procedureCode: String, updatedAt: Int, specialty: String, maximum: Double, attributes: [String: String], graceDays: Int, payer: String, phone: String, source: String, status: RollingSubstitutionRuleStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.maximum = maximum
            self.attributes = attributes
            self.graceDays = graceDays
            self.payer = payer
            self.phone = phone
            self.source = source
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

        func canMoveTo(_ next: RollingSubstitutionRuleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingSubstitutionRuleStatus.approved || next == RollingSubstitutionRuleStatus.withdrawn
            case .approved:
                return next == RollingSubstitutionRuleStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingSubstitutionRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling substitution rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((maximum + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSubstitutionRule {
            return RollingSubstitutionRule(
                code: code,
                name: name,
                procedureCode: procedureCode,
                updatedAt: updatedAt,
                specialty: specialty,
                maximum: maximum,
                attributes: attributes,
                graceDays: graceDays,
                payer: payer,
                phone: phone,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling substitution rule in status proposed.
    static func newRollingSubstitutionRule(_ code: String, name: String) -> RollingSubstitutionRule {
        return RollingSubstitutionRule(
            code: code,
            name: name,
            procedureCode: "",
            updatedAt: 0,
            specialty: "",
            maximum: 0.0,
            attributes: [:],
            graceDays: 0,
            payer: "",
            phone: "",
            source: "",
            status: RollingSubstitutionRuleStatus.proposed
        )
    }
}
