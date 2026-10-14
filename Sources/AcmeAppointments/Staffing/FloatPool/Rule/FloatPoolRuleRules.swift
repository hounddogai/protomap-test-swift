import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool rule must pass. Check returns its problems, or none.
    protocol FloatPoolRuleRule {
        func check(_ item: FloatPoolRule) -> [String]
    }

    final class FloatPoolRuleTitleLengthRule: FloatPoolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolRuleCodeLengthRule: FloatPoolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolRuleRequiredBedRule: FloatPoolRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolRule) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolRuleCodePrefixRule: FloatPoolRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FloatPoolRuleCopayRangeRule: FloatPoolRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolRule) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolRuleAllowedAllergyRule: FloatPoolRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool rule.
    final class FloatPoolRuleValidator {
        var rules: [any FloatPoolRuleRule]

        init(rules: [any FloatPoolRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolRule) -> [String] {
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

        func requireValid(_ item: FloatPoolRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolRule]) -> [String: [String]] {
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

    static func defaultFloatPoolRuleValidator() -> FloatPoolRuleValidator {
        return FloatPoolRuleValidator(
            rules: [
                FloatPoolRuleTitleLengthRule(maxLength: 120),
                FloatPoolRuleCodeLengthRule(maxLength: 86400),
                FloatPoolRuleRequiredBedRule(message: "float pool rule needs this field"),
                FloatPoolRuleCodePrefixRule(prefix: "OPS"),
                FloatPoolRuleCopayRangeRule(min: 7.8, max: 4391.2),
                FloatPoolRuleAllowedAllergyRule(allowed: ["strict", "seasonal"]),
            ]
        )
    }
}
