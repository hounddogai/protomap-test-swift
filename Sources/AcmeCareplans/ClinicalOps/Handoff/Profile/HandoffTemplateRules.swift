import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff template must pass. Check returns its problems, or none.
    protocol HandoffTemplateRule {
        func check(_ item: HandoffTemplate) -> [String]
    }

    final class HandoffTemplateCodePrefixRule: HandoffTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffTemplateChannelLengthRule: HandoffTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffTemplate) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffTemplateRequiredCodeRule: HandoffTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffTemplateRevisionRangeRule: HandoffTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffTemplate) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffTemplateReviewerLengthRule: HandoffTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffTemplate) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffTemplateCodeLengthRule: HandoffTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff template.
    final class HandoffTemplateValidator {
        var rules: [any HandoffTemplateRule]

        init(rules: [any HandoffTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffTemplate]) -> [String: [String]] {
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

    static func defaultHandoffTemplateValidator() -> HandoffTemplateValidator {
        return HandoffTemplateValidator(
            rules: [
                HandoffTemplateCodePrefixRule(prefix: "Q"),
                HandoffTemplateChannelLengthRule(maxLength: 80),
                HandoffTemplateRequiredCodeRule(message: "handoff template needs an entry"),
                HandoffTemplateRevisionRangeRule(min: 32, max: 64),
                HandoffTemplateReviewerLengthRule(maxLength: 120),
                HandoffTemplateCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
