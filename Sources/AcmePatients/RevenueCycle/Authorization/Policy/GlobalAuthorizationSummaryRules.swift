import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global authorization summary must pass. Check returns its problems, or none.
    protocol GlobalAuthorizationSummaryRule {
        func check(_ item: GlobalAuthorizationSummary) -> [String]
    }

    final class GlobalAuthorizationSummaryRequiredTitleRule: GlobalAuthorizationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAuthorizationSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAuthorizationSummaryTitleLengthRule: GlobalAuthorizationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAuthorizationSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAuthorizationSummaryRequiredCodeRule: GlobalAuthorizationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAuthorizationSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global authorization summary.
    final class GlobalAuthorizationSummaryValidator {
        var rules: [any GlobalAuthorizationSummaryRule]

        init(rules: [any GlobalAuthorizationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAuthorizationSummary) -> [String] {
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

        func requireValid(_ item: GlobalAuthorizationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAuthorizationSummary]) -> [String: [String]] {
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

    static func defaultGlobalAuthorizationSummaryValidator() -> GlobalAuthorizationSummaryValidator {
        return GlobalAuthorizationSummaryValidator(
            rules: [
                GlobalAuthorizationSummaryRequiredTitleRule(message: "global authorization summary needs an entry"),
                GlobalAuthorizationSummaryTitleLengthRule(maxLength: 1000),
                GlobalAuthorizationSummaryRequiredCodeRule(message: "global authorization summary needs an entry"),
            ]
        )
    }
}
