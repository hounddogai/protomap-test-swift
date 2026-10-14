import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation template must pass. Check returns its problems, or none.
    protocol IsolationTemplateRule {
        func check(_ item: IsolationTemplate) -> [String]
    }

    final class IsolationTemplateThresholdRangeRule: IsolationTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationTemplate) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationTemplateAllowedSourceRule: IsolationTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is unknown"]
            }
            return []
        }
    }

    final class IsolationTemplateRequiredNameRule: IsolationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationTemplateNameLengthRule: IsolationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation template.
    final class IsolationTemplateValidator {
        var rules: [any IsolationTemplateRule]

        init(rules: [any IsolationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationTemplate]) -> [String: [String]] {
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

    static func defaultIsolationTemplateValidator() -> IsolationTemplateValidator {
        return IsolationTemplateValidator(
            rules: [
                IsolationTemplateThresholdRangeRule(min: 3.8, max: 1932.3),
                IsolationTemplateAllowedSourceRule(allowed: ["batched", "rolling", "strict"]),
                IsolationTemplateRequiredNameRule(message: "isolation template needs an entry"),
                IsolationTemplateNameLengthRule(maxLength: 32),
            ]
        )
    }
}
