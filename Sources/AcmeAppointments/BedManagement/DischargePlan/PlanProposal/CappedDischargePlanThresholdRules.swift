import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped discharge plan threshold must pass. Check returns its problems, or none.
    protocol CappedDischargePlanThresholdRule {
        func check(_ item: CappedDischargePlanThreshold) -> [String]
    }

    final class CappedDischargePlanThresholdMinimumRangeRule: CappedDischargePlanThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDischargePlanThreshold) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedDischargePlanThresholdCodePrefixRule: CappedDischargePlanThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDischargePlanThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDischargePlanThresholdPinnedGuardRule: CappedDischargePlanThresholdRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedDischargePlanThreshold) -> [String] {
            if item.pinned && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CappedDischargePlanThresholdRequiredTitleRule: CappedDischargePlanThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDischargePlanThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDischargePlanThresholdWindowDaysRangeRule: CappedDischargePlanThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDischargePlanThreshold) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped discharge plan threshold.
    final class CappedDischargePlanThresholdValidator {
        var rules: [any CappedDischargePlanThresholdRule]

        init(rules: [any CappedDischargePlanThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDischargePlanThreshold) -> [String] {
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

        func requireValid(_ item: CappedDischargePlanThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDischargePlanThreshold]) -> [String: [String]] {
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

    static func defaultCappedDischargePlanThresholdValidator() -> CappedDischargePlanThresholdValidator {
        return CappedDischargePlanThresholdValidator(
            rules: [
                CappedDischargePlanThresholdMinimumRangeRule(min: 8.7, max: 2659.5),
                CappedDischargePlanThresholdCodePrefixRule(prefix: "X"),
                CappedDischargePlanThresholdPinnedGuardRule(limit: 4.0),
                CappedDischargePlanThresholdRequiredTitleRule(
                    message: "capped discharge plan threshold needs this field"
                ),
                CappedDischargePlanThresholdWindowDaysRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
