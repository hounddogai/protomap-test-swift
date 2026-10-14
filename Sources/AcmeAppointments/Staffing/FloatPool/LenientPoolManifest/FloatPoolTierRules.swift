import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool tier must pass. Check returns its problems, or none.
    protocol FloatPoolTierRule {
        func check(_ item: FloatPoolTier) -> [String]
    }

    final class FloatPoolTierRequiredCodeRule: FloatPoolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolTierRequiredLocaleRule: FloatPoolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolTier) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolTierRequiredTitleRule: FloatPoolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolTierLocaleLengthRule: FloatPoolTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool tier.
    final class FloatPoolTierValidator {
        var rules: [any FloatPoolTierRule]

        init(rules: [any FloatPoolTierRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolTier]) -> [String: [String]] {
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

    static func defaultFloatPoolTierValidator() -> FloatPoolTierValidator {
        return FloatPoolTierValidator(
            rules: [
                FloatPoolTierRequiredCodeRule(message: "float pool tier needs a value"),
                FloatPoolTierRequiredLocaleRule(message: "float pool tier needs this field"),
                FloatPoolTierRequiredTitleRule(message: "float pool tier needs a value"),
                FloatPoolTierLocaleLengthRule(maxLength: 3600),
            ]
        )
    }
}
