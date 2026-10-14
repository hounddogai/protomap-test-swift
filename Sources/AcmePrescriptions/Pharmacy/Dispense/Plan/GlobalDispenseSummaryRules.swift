import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global dispense summary must pass. Check returns its problems, or none.
    protocol GlobalDispenseSummaryRule {
        func check(_ item: GlobalDispenseSummary) -> [String]
    }

    final class GlobalDispenseSummaryCodeLengthRule: GlobalDispenseSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDispenseSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDispenseSummaryRequiredCodeRule: GlobalDispenseSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDispenseSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDispenseSummaryQuantityRangeRule: GlobalDispenseSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDispenseSummary) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalDispenseSummaryAllowedCodeRule: GlobalDispenseSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDispenseSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class GlobalDispenseSummaryLocaleLengthRule: GlobalDispenseSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDispenseSummary) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global dispense summary.
    final class GlobalDispenseSummaryValidator {
        var rules: [any GlobalDispenseSummaryRule]

        init(rules: [any GlobalDispenseSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDispenseSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDispenseSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDispenseSummary]) -> [String: [String]] {
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

    static func defaultGlobalDispenseSummaryValidator() -> GlobalDispenseSummaryValidator {
        return GlobalDispenseSummaryValidator(
            rules: [
                GlobalDispenseSummaryCodeLengthRule(maxLength: 80),
                GlobalDispenseSummaryRequiredCodeRule(message: "global dispense summary needs a value"),
                GlobalDispenseSummaryQuantityRangeRule(min: 255, max: 3600),
                GlobalDispenseSummaryAllowedCodeRule(allowed: ["batched"]),
                GlobalDispenseSummaryLocaleLengthRule(maxLength: 16),
            ]
        )
    }
}
