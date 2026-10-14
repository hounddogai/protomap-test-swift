import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority entry must pass. Check returns its problems, or none.
    protocol PriorityEntryRule {
        func check(_ item: PriorityEntry) -> [String]
    }

    final class PriorityEntryRequiredCodeRule: PriorityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityEntryPayerLengthRule: PriorityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityEntry) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityEntryWindowDaysRangeRule: PriorityEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityEntry) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityEntryRequiredPayerRule: PriorityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityEntry) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority entry.
    final class PriorityEntryValidator {
        var rules: [any PriorityEntryRule]

        init(rules: [any PriorityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityEntry]) -> [String: [String]] {
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

    static func defaultPriorityEntryValidator() -> PriorityEntryValidator {
        return PriorityEntryValidator(
            rules: [
                PriorityEntryRequiredCodeRule(message: "priority entry needs a value"),
                PriorityEntryPayerLengthRule(maxLength: 1000),
                PriorityEntryWindowDaysRangeRule(min: 64, max: 86400),
                PriorityEntryRequiredPayerRule(message: "priority entry needs this field"),
            ]
        )
    }
}
