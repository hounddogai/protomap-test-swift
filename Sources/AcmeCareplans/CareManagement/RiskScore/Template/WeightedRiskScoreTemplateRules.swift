import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted risk score template must pass. Check returns its problems, or none.
    protocol WeightedRiskScoreTemplateRule {
        func check(_ item: WeightedRiskScoreTemplate) -> [String]
    }

    final class WeightedRiskScoreTemplateBudgetRangeRule: WeightedRiskScoreTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRiskScoreTemplate) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTemplateRequiredTitleRule: WeightedRiskScoreTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRiskScoreTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRiskScoreTemplateAllowedChannelRule: WeightedRiskScoreTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedRiskScoreTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is out of range"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTemplateExpiresAtRangeRule: WeightedRiskScoreTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRiskScoreTemplate) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTemplateChannelLengthRule: WeightedRiskScoreTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreTemplate) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScoreTemplateNameLengthRule: WeightedRiskScoreTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScoreTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted risk score template.
    final class WeightedRiskScoreTemplateValidator {
        var rules: [any WeightedRiskScoreTemplateRule]

        init(rules: [any WeightedRiskScoreTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRiskScoreTemplate) -> [String] {
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

        func requireValid(_ item: WeightedRiskScoreTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRiskScoreTemplate]) -> [String: [String]] {
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

    static func defaultWeightedRiskScoreTemplateValidator() -> WeightedRiskScoreTemplateValidator {
        return WeightedRiskScoreTemplateValidator(
            rules: [
                WeightedRiskScoreTemplateBudgetRangeRule(min: 6.5, max: 1083.6),
                WeightedRiskScoreTemplateRequiredTitleRule(message: "weighted risk score template needs an entry"),
                WeightedRiskScoreTemplateAllowedChannelRule(allowed: ["strict", "scheduled", "global"]),
                WeightedRiskScoreTemplateExpiresAtRangeRule(min: 80, max: 3600),
                WeightedRiskScoreTemplateChannelLengthRule(maxLength: 3600),
                WeightedRiskScoreTemplateNameLengthRule(maxLength: 64),
            ]
        )
    }
}
