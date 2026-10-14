import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled modality summary must pass. Check returns its problems, or none.
    protocol ScheduledModalitySummaryRule {
        func check(_ item: ScheduledModalitySummary) -> [String]
    }

    final class ScheduledModalitySummaryAllowedWardRule: ScheduledModalitySummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledModalitySummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is above maximum"]
            }
            return []
        }
    }

    final class ScheduledModalitySummaryCodePrefixRule: ScheduledModalitySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledModalitySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledModalitySummaryRequiredNameRule: ScheduledModalitySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledModalitySummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledModalitySummaryWeightRangeRule: ScheduledModalitySummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledModalitySummary) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled modality summary.
    final class ScheduledModalitySummaryValidator {
        var rules: [any ScheduledModalitySummaryRule]

        init(rules: [any ScheduledModalitySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledModalitySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledModalitySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledModalitySummary]) -> [String: [String]] {
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

    static func defaultScheduledModalitySummaryValidator() -> ScheduledModalitySummaryValidator {
        return ScheduledModalitySummaryValidator(
            rules: [
                ScheduledModalitySummaryAllowedWardRule(allowed: ["strict", "capped"]),
                ScheduledModalitySummaryCodePrefixRule(prefix: "Q"),
                ScheduledModalitySummaryRequiredNameRule(message: "scheduled modality summary needs an entry"),
                ScheduledModalitySummaryWeightRangeRule(min: 7.9, max: 936.0),
            ]
        )
    }
}
