import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched isolation window must pass. Check returns its problems, or none.
    protocol BatchedIsolationWindowRule {
        func check(_ item: BatchedIsolationWindow) -> [String]
    }

    final class BatchedIsolationWindowAllowedCurrencyRule: BatchedIsolationWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedIsolationWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is above maximum"]
            }
            return []
        }
    }

    final class BatchedIsolationWindowCodeLengthRule: BatchedIsolationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedIsolationWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedIsolationWindowRequiredCodeRule: BatchedIsolationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedIsolationWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched isolation window.
    final class BatchedIsolationWindowValidator {
        var rules: [any BatchedIsolationWindowRule]

        init(rules: [any BatchedIsolationWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedIsolationWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedIsolationWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedIsolationWindow]) -> [String: [String]] {
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

    static func defaultBatchedIsolationWindowValidator() -> BatchedIsolationWindowValidator {
        return BatchedIsolationWindowValidator(
            rules: [
                BatchedIsolationWindowAllowedCurrencyRule(allowed: ["global"]),
                BatchedIsolationWindowCodeLengthRule(maxLength: 32),
                BatchedIsolationWindowRequiredCodeRule(message: "batched isolation window needs a value"),
            ]
        )
    }
}
