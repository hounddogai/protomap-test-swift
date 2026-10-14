import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority target must pass. Check returns its problems, or none.
    protocol PriorityTargetRule {
        func check(_ item: PriorityTarget) -> [String]
    }

    final class PriorityTargetCodeLengthRule: PriorityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityTargetExpiresAtRangeRule: PriorityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityTarget) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityTargetRequiredCurrencyRule: PriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityTarget) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityTargetSourceLengthRule: PriorityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityTarget) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority target.
    final class PriorityTargetValidator {
        var rules: [any PriorityTargetRule]

        init(rules: [any PriorityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityTarget]) -> [String: [String]] {
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

    static func defaultPriorityTargetValidator() -> PriorityTargetValidator {
        return PriorityTargetValidator(
            rules: [
                PriorityTargetCodeLengthRule(maxLength: 16),
                PriorityTargetExpiresAtRangeRule(min: 120, max: 1000),
                PriorityTargetRequiredCurrencyRule(message: "priority target needs an entry"),
                PriorityTargetSourceLengthRule(maxLength: 64),
            ]
        )
    }
}
