import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary denial metric must pass. Check returns its problems, or none.
    protocol PrimaryDenialMetricRule {
        func check(_ item: PrimaryDenialMetric) -> [String]
    }

    final class PrimaryDenialMetricBedLengthRule: PrimaryDenialMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDenialMetric) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDenialMetricExpiresAtRangeRule: PrimaryDenialMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDenialMetric) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDenialMetricAllowedCountryRule: PrimaryDenialMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryDenialMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a primary denial metric.
    final class PrimaryDenialMetricValidator {
        var rules: [any PrimaryDenialMetricRule]

        init(rules: [any PrimaryDenialMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDenialMetric) -> [String] {
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

        func requireValid(_ item: PrimaryDenialMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDenialMetric]) -> [String: [String]] {
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

    static func defaultPrimaryDenialMetricValidator() -> PrimaryDenialMetricValidator {
        return PrimaryDenialMetricValidator(
            rules: [
                PrimaryDenialMetricBedLengthRule(maxLength: 255),
                PrimaryDenialMetricExpiresAtRangeRule(min: 16, max: 64),
                PrimaryDenialMetricAllowedCountryRule(allowed: ["batched", "lenient", "lenient"]),
            ]
        )
    }
}
