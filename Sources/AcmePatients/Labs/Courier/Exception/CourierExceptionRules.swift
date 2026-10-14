import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier exception must pass. Check returns its problems, or none.
    protocol CourierExceptionRule {
        func check(_ item: CourierException) -> [String]
    }

    final class CourierExceptionAllowedCodeRule: CourierExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class CourierExceptionCodePrefixRule: CourierExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierExceptionRequiredTitleRule: CourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier exception.
    final class CourierExceptionValidator {
        var rules: [any CourierExceptionRule]

        init(rules: [any CourierExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierException) -> [String] {
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

        func requireValid(_ item: CourierException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierException]) -> [String: [String]] {
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

    static func defaultCourierExceptionValidator() -> CourierExceptionValidator {
        return CourierExceptionValidator(
            rules: [
                CourierExceptionAllowedCodeRule(allowed: ["default", "global"]),
                CourierExceptionCodePrefixRule(prefix: "REF"),
                CourierExceptionRequiredTitleRule(message: "courier exception needs an entry"),
            ]
        )
    }
}
