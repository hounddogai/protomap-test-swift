import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback rounding metric must pass. Check returns its problems, or none.
    protocol FallbackRoundingMetricRule {
        func check(_ item: FallbackRoundingMetric) -> [String]
    }

    final class FallbackRoundingMetricPatientRefLengthRule: FallbackRoundingMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRoundingMetric) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRoundingMetricRequiredPatientRefRule: FallbackRoundingMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingMetric) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingMetricRequiredCodeRule: FallbackRoundingMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingMetricStartsAtRangeRule: FallbackRoundingMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRoundingMetric) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback rounding metric.
    final class FallbackRoundingMetricValidator {
        var rules: [any FallbackRoundingMetricRule]

        init(rules: [any FallbackRoundingMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRoundingMetric) -> [String] {
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

        func requireValid(_ item: FallbackRoundingMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRoundingMetric]) -> [String: [String]] {
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

    static func defaultFallbackRoundingMetricValidator() -> FallbackRoundingMetricValidator {
        return FallbackRoundingMetricValidator(
            rules: [
                FallbackRoundingMetricPatientRefLengthRule(maxLength: 255),
                FallbackRoundingMetricRequiredPatientRefRule(message: "fallback rounding metric needs an entry"),
                FallbackRoundingMetricRequiredCodeRule(message: "fallback rounding metric needs a value"),
                FallbackRoundingMetricStartsAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
