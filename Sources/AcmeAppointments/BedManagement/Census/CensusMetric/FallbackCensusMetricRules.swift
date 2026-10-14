import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback census metric must pass. Check returns its problems, or none.
    protocol FallbackCensusMetricRule {
        func check(_ item: FallbackCensusMetric) -> [String]
    }

    final class FallbackCensusMetricAllowedNameRule: FallbackCensusMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCensusMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class FallbackCensusMetricRefillsRangeRule: FallbackCensusMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCensusMetric) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCensusMetricRatioRangeRule: FallbackCensusMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCensusMetric) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback census metric.
    final class FallbackCensusMetricValidator {
        var rules: [any FallbackCensusMetricRule]

        init(rules: [any FallbackCensusMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCensusMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCensusMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCensusMetric]) -> [String: [String]] {
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

    static func defaultFallbackCensusMetricValidator() -> FallbackCensusMetricValidator {
        return FallbackCensusMetricValidator(
            rules: [
                FallbackCensusMetricAllowedNameRule(allowed: ["seasonal"]),
                FallbackCensusMetricRefillsRangeRule(min: 1000, max: 3600),
                FallbackCensusMetricRatioRangeRule(min: 5.9, max: 1723.5),
            ]
        )
    }
}
