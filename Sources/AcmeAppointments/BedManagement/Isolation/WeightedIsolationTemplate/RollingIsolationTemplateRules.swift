import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling isolation template must pass. Check returns its problems, or none.
    protocol RollingIsolationTemplateRule {
        func check(_ item: RollingIsolationTemplate) -> [String]
    }

    final class RollingIsolationTemplateCountryLengthRule: RollingIsolationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingIsolationTemplate) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingIsolationTemplateRequiredNameRule: RollingIsolationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingIsolationTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingIsolationTemplateCodePrefixRule: RollingIsolationTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingIsolationTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingIsolationTemplateRatioRangeRule: RollingIsolationTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingIsolationTemplate) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingIsolationTemplateLabelLengthRule: RollingIsolationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingIsolationTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling isolation template.
    final class RollingIsolationTemplateValidator {
        var rules: [any RollingIsolationTemplateRule]

        init(rules: [any RollingIsolationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingIsolationTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingIsolationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingIsolationTemplate]) -> [String: [String]] {
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

    static func defaultRollingIsolationTemplateValidator() -> RollingIsolationTemplateValidator {
        return RollingIsolationTemplateValidator(
            rules: [
                RollingIsolationTemplateCountryLengthRule(maxLength: 64),
                RollingIsolationTemplateRequiredNameRule(message: "rolling isolation template needs a value"),
                RollingIsolationTemplateCodePrefixRule(prefix: "OPS"),
                RollingIsolationTemplateRatioRangeRule(min: 8.7, max: 1007.9),
                RollingIsolationTemplateLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
