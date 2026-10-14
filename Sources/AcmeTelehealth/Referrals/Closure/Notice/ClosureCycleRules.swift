import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure cycle must pass. Check returns its problems, or none.
    protocol ClosureCycleRule {
        func check(_ item: ClosureCycle) -> [String]
    }

    final class ClosureCycleDurationMinutesRangeRule: ClosureCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureCycle) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureCycleRequiredLabelRule: ClosureCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureCycleCodePrefixRule: ClosureCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure cycle.
    final class ClosureCycleValidator {
        var rules: [any ClosureCycleRule]

        init(rules: [any ClosureCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureCycle) -> [String] {
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

        func requireValid(_ item: ClosureCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureCycle]) -> [String: [String]] {
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

    static func defaultClosureCycleValidator() -> ClosureCycleValidator {
        return ClosureCycleValidator(
            rules: [
                ClosureCycleDurationMinutesRangeRule(min: 255, max: 1000),
                ClosureCycleRequiredLabelRule(message: "closure cycle needs a value"),
                ClosureCycleCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
