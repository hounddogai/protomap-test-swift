import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global shift agreement must pass. Check returns its problems, or none.
    protocol GlobalShiftAgreementRule {
        func check(_ item: GlobalShiftAgreement) -> [String]
    }

    final class GlobalShiftAgreementRequiredCodeRule: GlobalShiftAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalShiftAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalShiftAgreementCodePrefixRule: GlobalShiftAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalShiftAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalShiftAgreementNameLengthRule: GlobalShiftAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftAgreementUnitLengthRule: GlobalShiftAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftAgreement) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftAgreementArchivedGuardRule: GlobalShiftAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalShiftAgreement) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a global shift agreement.
    final class GlobalShiftAgreementValidator {
        var rules: [any GlobalShiftAgreementRule]

        init(rules: [any GlobalShiftAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalShiftAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalShiftAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalShiftAgreement]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultGlobalShiftAgreementValidator() -> GlobalShiftAgreementValidator {
        return GlobalShiftAgreementValidator(
            rules: [
                GlobalShiftAgreementRequiredCodeRule(message: "global shift agreement needs this field"),
                GlobalShiftAgreementCodePrefixRule(prefix: "X"),
                GlobalShiftAgreementNameLengthRule(maxLength: 120),
                GlobalShiftAgreementUnitLengthRule(maxLength: 32),
                GlobalShiftAgreementArchivedGuardRule(limit: 5.5),
            ]
        )
    }
}
