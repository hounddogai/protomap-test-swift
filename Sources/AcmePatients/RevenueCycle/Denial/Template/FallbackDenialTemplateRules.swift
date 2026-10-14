import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback denial template must pass. Check returns its problems, or none.
    protocol FallbackDenialTemplateRule {
        func check(_ item: FallbackDenialTemplate) -> [String]
    }

    final class FallbackDenialTemplateUpdatedAtRangeRule: FallbackDenialTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDenialTemplate) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDenialTemplateRequiredChannelRule: FallbackDenialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialTemplate) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialTemplateCapacityRangeRule: FallbackDenialTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDenialTemplate) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDenialTemplateDiagnosisCodeLengthRule: FallbackDenialTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialTemplate) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback denial template.
    final class FallbackDenialTemplateValidator {
        var rules: [any FallbackDenialTemplateRule]

        init(rules: [any FallbackDenialTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDenialTemplate) -> [String] {
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

        func requireValid(_ item: FallbackDenialTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDenialTemplate]) -> [String: [String]] {
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

    static func defaultFallbackDenialTemplateValidator() -> FallbackDenialTemplateValidator {
        return FallbackDenialTemplateValidator(
            rules: [
                FallbackDenialTemplateUpdatedAtRangeRule(min: 32, max: 80),
                FallbackDenialTemplateRequiredChannelRule(message: "fallback denial template needs an entry"),
                FallbackDenialTemplateCapacityRangeRule(min: 80, max: 120),
                FallbackDenialTemplateDiagnosisCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
