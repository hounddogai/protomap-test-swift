import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict worklist mapping must pass. Check returns its problems, or none.
    protocol StrictWorklistMappingRule {
        func check(_ item: StrictWorklistMapping) -> [String]
    }

    final class StrictWorklistMappingCodePrefixRule: StrictWorklistMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictWorklistMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictWorklistMappingRequiredTimezoneRule: StrictWorklistMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistMapping) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWorklistMappingTitleLengthRule: StrictWorklistMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWorklistMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWorklistMappingRequiredTitleRule: StrictWorklistMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict worklist mapping.
    final class StrictWorklistMappingValidator {
        var rules: [any StrictWorklistMappingRule]

        init(rules: [any StrictWorklistMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWorklistMapping) -> [String] {
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

        func requireValid(_ item: StrictWorklistMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWorklistMapping]) -> [String: [String]] {
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

    static func defaultStrictWorklistMappingValidator() -> StrictWorklistMappingValidator {
        return StrictWorklistMappingValidator(
            rules: [
                StrictWorklistMappingCodePrefixRule(prefix: "Q"),
                StrictWorklistMappingRequiredTimezoneRule(message: "strict worklist mapping needs a value"),
                StrictWorklistMappingTitleLengthRule(maxLength: 80),
                StrictWorklistMappingRequiredTitleRule(message: "strict worklist mapping needs a value"),
            ]
        )
    }
}
