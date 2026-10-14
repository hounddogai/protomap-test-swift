import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched authorization target must pass. Check returns its problems, or none.
    protocol BatchedAuthorizationTargetRule {
        func check(_ item: BatchedAuthorizationTarget) -> [String]
    }

    final class BatchedAuthorizationTargetRequiredCodeRule: BatchedAuthorizationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationTargetCreatedAtRangeRule: BatchedAuthorizationTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAuthorizationTarget) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationTargetWindowDaysRangeRule: BatchedAuthorizationTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAuthorizationTarget) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationTargetCodePrefixRule: BatchedAuthorizationTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedAuthorizationTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationTargetCodeLengthRule: BatchedAuthorizationTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAuthorizationTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched authorization target.
    final class BatchedAuthorizationTargetValidator {
        var rules: [any BatchedAuthorizationTargetRule]

        init(rules: [any BatchedAuthorizationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAuthorizationTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAuthorizationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAuthorizationTarget]) -> [String: [String]] {
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

    static func defaultBatchedAuthorizationTargetValidator() -> BatchedAuthorizationTargetValidator {
        return BatchedAuthorizationTargetValidator(
            rules: [
                BatchedAuthorizationTargetRequiredCodeRule(message: "batched authorization target needs a value"),
                BatchedAuthorizationTargetCreatedAtRangeRule(min: 16, max: 120),
                BatchedAuthorizationTargetWindowDaysRangeRule(min: 16, max: 86400),
                BatchedAuthorizationTargetCodePrefixRule(prefix: "ACM"),
                BatchedAuthorizationTargetCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
