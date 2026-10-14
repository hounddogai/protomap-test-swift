import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority override must pass. Check returns its problems, or none.
    protocol PriorityOverrideRule {
        func check(_ item: PriorityOverride) -> [String]
    }

    final class PriorityOverrideAllowedTimezoneRule: PriorityOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is inconsistent"]
            }
            return []
        }
    }

    final class PriorityOverrideSequenceRangeRule: PriorityOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityOverride) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityOverrideBudgetRangeRule: PriorityOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityOverride) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a priority override.
    final class PriorityOverrideValidator {
        var rules: [any PriorityOverrideRule]

        init(rules: [any PriorityOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityOverride) -> [String] {
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

        func requireValid(_ item: PriorityOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityOverride]) -> [String: [String]] {
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

    static func defaultPriorityOverrideValidator() -> PriorityOverrideValidator {
        return PriorityOverrideValidator(
            rules: [
                PriorityOverrideAllowedTimezoneRule(allowed: ["primary", "batched", "batched"]),
                PriorityOverrideSequenceRangeRule(min: 80, max: 120),
                PriorityOverrideBudgetRangeRule(min: 3.7, max: 3334.0),
            ]
        )
    }
}
