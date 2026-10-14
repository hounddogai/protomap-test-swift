import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap template must pass. Check returns its problems, or none.
    protocol CareGapTemplateRule {
        func check(_ item: CareGapTemplate) -> [String]
    }

    final class CareGapTemplateThresholdRangeRule: CareGapTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapTemplate) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapTemplatePriorityRangeRule: CareGapTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapTemplate) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapTemplateCodePrefixRule: CareGapTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap template.
    final class CareGapTemplateValidator {
        var rules: [any CareGapTemplateRule]

        init(rules: [any CareGapTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapTemplate]) -> [String: [String]] {
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

    static func defaultCareGapTemplateValidator() -> CareGapTemplateValidator {
        return CareGapTemplateValidator(
            rules: [
                CareGapTemplateThresholdRangeRule(min: 2.6, max: 3381.5),
                CareGapTemplatePriorityRangeRule(min: 120, max: 255),
                CareGapTemplateCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
