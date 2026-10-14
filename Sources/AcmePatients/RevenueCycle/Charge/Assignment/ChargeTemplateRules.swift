import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge template must pass. Check returns its problems, or none.
    protocol ChargeTemplateRule {
        func check(_ item: ChargeTemplate) -> [String]
    }

    final class ChargeTemplateLabelLengthRule: ChargeTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeTemplateGraceDaysRangeRule: ChargeTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeTemplate) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeTemplateCreatedAtRangeRule: ChargeTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeTemplate) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeTemplateCodeLengthRule: ChargeTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge template.
    final class ChargeTemplateValidator {
        var rules: [any ChargeTemplateRule]

        init(rules: [any ChargeTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeTemplate]) -> [String: [String]] {
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

    static func defaultChargeTemplateValidator() -> ChargeTemplateValidator {
        return ChargeTemplateValidator(
            rules: [
                ChargeTemplateLabelLengthRule(maxLength: 1000),
                ChargeTemplateGraceDaysRangeRule(min: 32, max: 1000),
                ChargeTemplateCreatedAtRangeRule(min: 1000, max: 3600),
                ChargeTemplateCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
