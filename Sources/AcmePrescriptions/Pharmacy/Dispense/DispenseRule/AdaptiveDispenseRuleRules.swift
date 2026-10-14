import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive dispense rule must pass. Check returns its problems, or none.
    protocol AdaptiveDispenseRuleRule {
        func check(_ item: AdaptiveDispenseRule) -> [String]
    }

    final class AdaptiveDispenseRuleRatioRangeRule: AdaptiveDispenseRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDispenseRule) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveDispenseRuleCodeLengthRule: AdaptiveDispenseRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDispenseRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDispenseRuleRequiredNotesRule: AdaptiveDispenseRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDispenseRule) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDispenseRuleAllowedCodeRule: AdaptiveDispenseRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveDispenseRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class AdaptiveDispenseRuleNotesLengthRule: AdaptiveDispenseRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDispenseRule) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive dispense rule.
    final class AdaptiveDispenseRuleValidator {
        var rules: [any AdaptiveDispenseRuleRule]

        init(rules: [any AdaptiveDispenseRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDispenseRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveDispenseRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDispenseRule]) -> [String: [String]] {
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

    static func defaultAdaptiveDispenseRuleValidator() -> AdaptiveDispenseRuleValidator {
        return AdaptiveDispenseRuleValidator(
            rules: [
                AdaptiveDispenseRuleRatioRangeRule(min: 6.5, max: 3004.5),
                AdaptiveDispenseRuleCodeLengthRule(maxLength: 64),
                AdaptiveDispenseRuleRequiredNotesRule(message: "adaptive dispense rule needs this field"),
                AdaptiveDispenseRuleAllowedCodeRule(allowed: ["lenient", "default", "seasonal"]),
                AdaptiveDispenseRuleNotesLengthRule(maxLength: 32),
            ]
        )
    }
}
