import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched authorization baseline must pass. Check returns its problems, or none.
    protocol BatchedAuthorizationBaselineRule {
        func check(_ item: BatchedAuthorizationBaseline) -> [String]
    }

    final class BatchedAuthorizationBaselineRequiredCodeRule: BatchedAuthorizationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationBaselineRequiredWardRule: BatchedAuthorizationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationBaseline) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationBaselineDurationMinutesRangeRule: BatchedAuthorizationBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAuthorizationBaseline) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationBaselineNameLengthRule: BatchedAuthorizationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAuthorizationBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched authorization baseline.
    final class BatchedAuthorizationBaselineValidator {
        var rules: [any BatchedAuthorizationBaselineRule]

        init(rules: [any BatchedAuthorizationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAuthorizationBaseline) -> [String] {
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

        func requireValid(_ item: BatchedAuthorizationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAuthorizationBaseline]) -> [String: [String]] {
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

    static func defaultBatchedAuthorizationBaselineValidator() -> BatchedAuthorizationBaselineValidator {
        return BatchedAuthorizationBaselineValidator(
            rules: [
                BatchedAuthorizationBaselineRequiredCodeRule(
                    message: "batched authorization baseline needs this field"
                ),
                BatchedAuthorizationBaselineRequiredWardRule(
                    message: "batched authorization baseline needs this field"
                ),
                BatchedAuthorizationBaselineDurationMinutesRangeRule(min: 64, max: 1000),
                BatchedAuthorizationBaselineNameLengthRule(maxLength: 80),
            ]
        )
    }
}
