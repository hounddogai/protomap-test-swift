import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict isolation milestone must pass. Check returns its problems, or none.
    protocol StrictIsolationMilestoneRule {
        func check(_ item: StrictIsolationMilestone) -> [String]
    }

    final class StrictIsolationMilestoneAllowedNameRule: StrictIsolationMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictIsolationMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class StrictIsolationMilestoneCodePrefixRule: StrictIsolationMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictIsolationMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictIsolationMilestoneMarginRangeRule: StrictIsolationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictIsolationMilestone) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictIsolationMilestoneRequiredCodeRule: StrictIsolationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictIsolationMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictIsolationMilestoneExpiresAtRangeRule: StrictIsolationMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictIsolationMilestone) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict isolation milestone.
    final class StrictIsolationMilestoneValidator {
        var rules: [any StrictIsolationMilestoneRule]

        init(rules: [any StrictIsolationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictIsolationMilestone) -> [String] {
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

        func requireValid(_ item: StrictIsolationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictIsolationMilestone]) -> [String: [String]] {
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

    static func defaultStrictIsolationMilestoneValidator() -> StrictIsolationMilestoneValidator {
        return StrictIsolationMilestoneValidator(
            rules: [
                StrictIsolationMilestoneAllowedNameRule(allowed: []),
                StrictIsolationMilestoneCodePrefixRule(prefix: "OPS"),
                StrictIsolationMilestoneMarginRangeRule(min: 8.2, max: 3704.6),
                StrictIsolationMilestoneRequiredCodeRule(message: "strict isolation milestone needs this field"),
                StrictIsolationMilestoneExpiresAtRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
