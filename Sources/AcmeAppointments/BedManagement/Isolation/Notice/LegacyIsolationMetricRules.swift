import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy isolation metric must pass. Check returns its problems, or none.
    protocol LegacyIsolationMetricRule {
        func check(_ item: LegacyIsolationMetric) -> [String]
    }

    final class LegacyIsolationMetricRequiredFacilityRule: LegacyIsolationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationMetric) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationMetricAllowedFacilityRule: LegacyIsolationMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyIsolationMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is inconsistent"]
            }
            return []
        }
    }

    final class LegacyIsolationMetricGraceDaysRangeRule: LegacyIsolationMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyIsolationMetric) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyIsolationMetricRequiredNameRule: LegacyIsolationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationMetricStartsAtRangeRule: LegacyIsolationMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyIsolationMetric) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy isolation metric.
    final class LegacyIsolationMetricValidator {
        var rules: [any LegacyIsolationMetricRule]

        init(rules: [any LegacyIsolationMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyIsolationMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyIsolationMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyIsolationMetric]) -> [String: [String]] {
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

    static func defaultLegacyIsolationMetricValidator() -> LegacyIsolationMetricValidator {
        return LegacyIsolationMetricValidator(
            rules: [
                LegacyIsolationMetricRequiredFacilityRule(message: "legacy isolation metric needs a value"),
                LegacyIsolationMetricAllowedFacilityRule(allowed: ["default", "pending"]),
                LegacyIsolationMetricGraceDaysRangeRule(min: 120, max: 255),
                LegacyIsolationMetricRequiredNameRule(message: "legacy isolation metric needs this field"),
                LegacyIsolationMetricStartsAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
