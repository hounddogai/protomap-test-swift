import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled priority mapping must pass. Check returns its problems, or none.
    protocol ScheduledPriorityMappingRule {
        func check(_ item: ScheduledPriorityMapping) -> [String]
    }

    final class ScheduledPriorityMappingTitleLengthRule: ScheduledPriorityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPriorityMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPriorityMappingCodeLengthRule: ScheduledPriorityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPriorityMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPriorityMappingRequiredTitleRule: ScheduledPriorityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPriorityMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled priority mapping.
    final class ScheduledPriorityMappingValidator {
        var rules: [any ScheduledPriorityMappingRule]

        init(rules: [any ScheduledPriorityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPriorityMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledPriorityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPriorityMapping]) -> [String: [String]] {
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

    static func defaultScheduledPriorityMappingValidator() -> ScheduledPriorityMappingValidator {
        return ScheduledPriorityMappingValidator(
            rules: [
                ScheduledPriorityMappingTitleLengthRule(maxLength: 120),
                ScheduledPriorityMappingCodeLengthRule(maxLength: 3600),
                ScheduledPriorityMappingRequiredTitleRule(message: "scheduled priority mapping needs an entry"),
            ]
        )
    }
}
