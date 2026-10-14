import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure rollup must pass. Check returns its problems, or none.
    protocol ClosureRollupRule {
        func check(_ item: ClosureRollup) -> [String]
    }

    final class ClosureRollupCodeLengthRule: ClosureRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureRollupRequiredCodeRule: ClosureRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureRollupAttemptsRangeRule: ClosureRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureRollup) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureRollupNameLengthRule: ClosureRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure rollup.
    final class ClosureRollupValidator {
        var rules: [any ClosureRollupRule]

        init(rules: [any ClosureRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureRollup) -> [String] {
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

        func requireValid(_ item: ClosureRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureRollup]) -> [String: [String]] {
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

    static func defaultClosureRollupValidator() -> ClosureRollupValidator {
        return ClosureRollupValidator(
            rules: [
                ClosureRollupCodeLengthRule(maxLength: 16),
                ClosureRollupRequiredCodeRule(message: "closure rollup needs an entry"),
                ClosureRollupAttemptsRangeRule(min: 16, max: 32),
                ClosureRollupNameLengthRule(maxLength: 80),
            ]
        )
    }
}
