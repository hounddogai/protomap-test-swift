import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set entry must pass. Check returns its problems, or none.
    protocol OrderSetEntryRule {
        func check(_ item: OrderSetEntry) -> [String]
    }

    final class OrderSetEntryAttemptsRangeRule: OrderSetEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetEntry) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetEntryRequiredNameRule: OrderSetEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetEntryRequiredCodeRule: OrderSetEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetEntryScoreRangeRule: OrderSetEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetEntry) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set entry.
    final class OrderSetEntryValidator {
        var rules: [any OrderSetEntryRule]

        init(rules: [any OrderSetEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetEntry) -> [String] {
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

        func requireValid(_ item: OrderSetEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetEntry]) -> [String: [String]] {
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

    static func defaultOrderSetEntryValidator() -> OrderSetEntryValidator {
        return OrderSetEntryValidator(
            rules: [
                OrderSetEntryAttemptsRangeRule(min: 64, max: 86400),
                OrderSetEntryRequiredNameRule(message: "order set entry needs a value"),
                OrderSetEntryRequiredCodeRule(message: "order set entry needs an entry"),
                OrderSetEntryScoreRangeRule(min: 8.5, max: 4411.4),
            ]
        )
    }
}
