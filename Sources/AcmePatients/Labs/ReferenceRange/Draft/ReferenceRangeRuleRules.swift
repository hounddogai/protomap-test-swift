import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range rule must pass. Check returns its problems, or none.
    protocol ReferenceRangeRuleRule {
        func check(_ item: ReferenceRangeRule) -> [String]
    }

    final class ReferenceRangeRuleRequiredPatientRefRule: ReferenceRangeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeRule) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeRuleCodePrefixRule: ReferenceRangeRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeRuleCountryLengthRule: ReferenceRangeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeRule) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeRuleScoreRangeRule: ReferenceRangeRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeRule) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeRuleLabelLengthRule: ReferenceRangeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range rule.
    final class ReferenceRangeRuleValidator {
        var rules: [any ReferenceRangeRuleRule]

        init(rules: [any ReferenceRangeRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeRule]) -> [String: [String]] {
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

    static func defaultReferenceRangeRuleValidator() -> ReferenceRangeRuleValidator {
        return ReferenceRangeRuleValidator(
            rules: [
                ReferenceRangeRuleRequiredPatientRefRule(message: "reference range rule needs a value"),
                ReferenceRangeRuleCodePrefixRule(prefix: "Q"),
                ReferenceRangeRuleCountryLengthRule(maxLength: 255),
                ReferenceRangeRuleScoreRangeRule(min: 2.8, max: 767.3),
                ReferenceRangeRuleLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
