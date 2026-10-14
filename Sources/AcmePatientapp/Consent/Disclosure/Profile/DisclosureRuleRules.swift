import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure rule must pass. Check returns its problems, or none.
    protocol DisclosureRuleRule {
        func check(_ item: DisclosureRule) -> [String]
    }

    final class DisclosureRuleBudgetRangeRule: DisclosureRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureRule) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureRuleCodeLengthRule: DisclosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRulePatientRefLengthRule: DisclosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRule) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRuleCodePrefixRule: DisclosureRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureRuleRequiredPatientRefRule: DisclosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRule) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureRuleRequiredUnitRule: DisclosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRule) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure rule.
    final class DisclosureRuleValidator {
        var rules: [any DisclosureRuleRule]

        init(rules: [any DisclosureRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureRule]) -> [String: [String]] {
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

    static func defaultDisclosureRuleValidator() -> DisclosureRuleValidator {
        return DisclosureRuleValidator(
            rules: [
                DisclosureRuleBudgetRangeRule(min: 7.7, max: 2518.3),
                DisclosureRuleCodeLengthRule(maxLength: 80),
                DisclosureRulePatientRefLengthRule(maxLength: 120),
                DisclosureRuleCodePrefixRule(prefix: "OPS"),
                DisclosureRuleRequiredPatientRefRule(message: "disclosure rule needs a value"),
                DisclosureRuleRequiredUnitRule(message: "disclosure rule needs an entry"),
            ]
        )
    }
}
