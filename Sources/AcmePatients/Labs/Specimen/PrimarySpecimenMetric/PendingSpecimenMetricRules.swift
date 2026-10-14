import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending specimen metric must pass. Check returns its problems, or none.
    protocol PendingSpecimenMetricRule {
        func check(_ item: PendingSpecimenMetric) -> [String]
    }

    final class PendingSpecimenMetricCodePrefixRule: PendingSpecimenMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingSpecimenMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingSpecimenMetricRequiredCodeRule: PendingSpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSpecimenMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSpecimenMetricCopayRangeRule: PendingSpecimenMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSpecimenMetric) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingSpecimenMetricAllowedCodeRule: PendingSpecimenMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingSpecimenMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class PendingSpecimenMetricAttemptsRangeRule: PendingSpecimenMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSpecimenMetric) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingSpecimenMetricGraceDaysRangeRule: PendingSpecimenMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSpecimenMetric) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending specimen metric.
    final class PendingSpecimenMetricValidator {
        var rules: [any PendingSpecimenMetricRule]

        init(rules: [any PendingSpecimenMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSpecimenMetric) -> [String] {
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

        func requireValid(_ item: PendingSpecimenMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSpecimenMetric]) -> [String: [String]] {
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

    static func defaultPendingSpecimenMetricValidator() -> PendingSpecimenMetricValidator {
        return PendingSpecimenMetricValidator(
            rules: [
                PendingSpecimenMetricCodePrefixRule(prefix: "X"),
                PendingSpecimenMetricRequiredCodeRule(message: "pending specimen metric needs this field"),
                PendingSpecimenMetricCopayRangeRule(min: 6.5, max: 4691.9),
                PendingSpecimenMetricAllowedCodeRule(allowed: ["seasonal", "adaptive"]),
                PendingSpecimenMetricAttemptsRangeRule(min: 80, max: 86400),
                PendingSpecimenMetricGraceDaysRangeRule(min: 32, max: 120),
            ]
        )
    }
}
