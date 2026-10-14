import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime cycle must pass. Check returns its problems, or none.
    protocol OvertimeCycleRule {
        func check(_ item: OvertimeCycle) -> [String]
    }

    final class OvertimeCycleRequiredCodeRule: OvertimeCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeCycleGraceDaysRangeRule: OvertimeCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeCycle) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeCycleMaximumRangeRule: OvertimeCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeCycle) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeCycleCodePrefixRule: OvertimeCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime cycle.
    final class OvertimeCycleValidator {
        var rules: [any OvertimeCycleRule]

        init(rules: [any OvertimeCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeCycle) -> [String] {
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

        func requireValid(_ item: OvertimeCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeCycle]) -> [String: [String]] {
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

    static func defaultOvertimeCycleValidator() -> OvertimeCycleValidator {
        return OvertimeCycleValidator(
            rules: [
                OvertimeCycleRequiredCodeRule(message: "overtime cycle needs an entry"),
                OvertimeCycleGraceDaysRangeRule(min: 16, max: 16),
                OvertimeCycleMaximumRangeRule(min: 3.7, max: 696.6),
                OvertimeCycleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
