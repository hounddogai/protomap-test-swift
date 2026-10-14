import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense baseline must pass. Check returns its problems, or none.
    protocol DispenseBaselineRule {
        func check(_ item: DispenseBaseline) -> [String]
    }

    final class DispenseBaselineGraceDaysRangeRule: DispenseBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBaseline) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseBaselineCodePrefixRule: DispenseBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseBaselineRequiredCodeRule: DispenseBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense baseline.
    final class DispenseBaselineValidator {
        var rules: [any DispenseBaselineRule]

        init(rules: [any DispenseBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseBaseline) -> [String] {
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

        func requireValid(_ item: DispenseBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseBaseline]) -> [String: [String]] {
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

    static func defaultDispenseBaselineValidator() -> DispenseBaselineValidator {
        return DispenseBaselineValidator(
            rules: [
                DispenseBaselineGraceDaysRangeRule(min: 32, max: 3600),
                DispenseBaselineCodePrefixRule(prefix: "Q"),
                DispenseBaselineRequiredCodeRule(message: "dispense baseline needs this field"),
            ]
        )
    }
}
