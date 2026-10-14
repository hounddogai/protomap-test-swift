import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual care protocol template must pass. Check returns its problems, or none.
    protocol ManualCareProtocolTemplateRule {
        func check(_ item: ManualCareProtocolTemplate) -> [String]
    }

    final class ManualCareProtocolTemplateLabelLengthRule: ManualCareProtocolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareProtocolTemplateCreatedAtRangeRule: ManualCareProtocolTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCareProtocolTemplate) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualCareProtocolTemplateCodePrefixRule: ManualCareProtocolTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCareProtocolTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual care protocol template.
    final class ManualCareProtocolTemplateValidator {
        var rules: [any ManualCareProtocolTemplateRule]

        init(rules: [any ManualCareProtocolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareProtocolTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCareProtocolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareProtocolTemplate]) -> [String: [String]] {
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

    static func defaultManualCareProtocolTemplateValidator() -> ManualCareProtocolTemplateValidator {
        return ManualCareProtocolTemplateValidator(
            rules: [
                ManualCareProtocolTemplateLabelLengthRule(maxLength: 86400),
                ManualCareProtocolTemplateCreatedAtRangeRule(min: 255, max: 86400),
                ManualCareProtocolTemplateCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
