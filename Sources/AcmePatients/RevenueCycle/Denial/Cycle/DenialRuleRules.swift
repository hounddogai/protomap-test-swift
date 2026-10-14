import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial rule must pass. Check returns its problems, or none.
    protocol DenialRuleRule {
        func check(_ item: DenialRule) -> [String]
    }

    final class DenialRuleRequiredFacilityRule: DenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialRule) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialRuleRequiredProcedureCodeRule: DenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialRule) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialRuleCodePrefixRule: DenialRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialRuleRequiredCodeRule: DenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialRuleDiscountRangeRule: DenialRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialRule) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial rule.
    final class DenialRuleValidator {
        var rules: [any DenialRuleRule]

        init(rules: [any DenialRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: DenialRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialRule]) -> [String: [String]] {
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

    static func defaultDenialRuleValidator() -> DenialRuleValidator {
        return DenialRuleValidator(
            rules: [
                DenialRuleRequiredFacilityRule(message: "denial rule needs this field"),
                DenialRuleRequiredProcedureCodeRule(message: "denial rule needs an entry"),
                DenialRuleCodePrefixRule(prefix: "REF"),
                DenialRuleRequiredCodeRule(message: "denial rule needs an entry"),
                DenialRuleDiscountRangeRule(min: 1.9, max: 4160.2),
            ]
        )
    }
}
