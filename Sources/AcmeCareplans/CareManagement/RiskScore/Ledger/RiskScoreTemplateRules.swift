import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score template must pass. Check returns its problems, or none.
    protocol RiskScoreTemplateRule {
        func check(_ item: RiskScoreTemplate) -> [String]
    }

    final class RiskScoreTemplateNameLengthRule: RiskScoreTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreTemplateCodePrefixRule: RiskScoreTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreTemplateRatioRangeRule: RiskScoreTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreTemplate) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreTemplateRequiredCodeRule: RiskScoreTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a risk score template.
    final class RiskScoreTemplateValidator {
        var rules: [any RiskScoreTemplateRule]

        init(rules: [any RiskScoreTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreTemplate) -> [String] {
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

        func requireValid(_ item: RiskScoreTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreTemplate]) -> [String: [String]] {
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

    static func defaultRiskScoreTemplateValidator() -> RiskScoreTemplateValidator {
        return RiskScoreTemplateValidator(
            rules: [
                RiskScoreTemplateNameLengthRule(maxLength: 80),
                RiskScoreTemplateCodePrefixRule(prefix: "OPS"),
                RiskScoreTemplateRatioRangeRule(min: 8.7, max: 3850.6),
                RiskScoreTemplateRequiredCodeRule(message: "risk score template needs an entry"),
            ]
        )
    }
}
