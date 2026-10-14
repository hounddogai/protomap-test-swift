import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched witness forecast must pass. Check returns its problems, or none.
    protocol BatchedWitnessForecastRule {
        func check(_ item: BatchedWitnessForecast) -> [String]
    }

    final class BatchedWitnessForecastVisibleGuardRule: BatchedWitnessForecastRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedWitnessForecast) -> [String] {
            if item.visible && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class BatchedWitnessForecastThresholdRangeRule: BatchedWitnessForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedWitnessForecast) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedWitnessForecastWindowDaysRangeRule: BatchedWitnessForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedWitnessForecast) -> [String] {
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

    final class BatchedWitnessForecastTitleLengthRule: BatchedWitnessForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched witness forecast.
    final class BatchedWitnessForecastValidator {
        var rules: [any BatchedWitnessForecastRule]

        init(rules: [any BatchedWitnessForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedWitnessForecast) -> [String] {
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

        func requireValid(_ item: BatchedWitnessForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedWitnessForecast]) -> [String: [String]] {
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

    static func defaultBatchedWitnessForecastValidator() -> BatchedWitnessForecastValidator {
        return BatchedWitnessForecastValidator(
            rules: [
                BatchedWitnessForecastVisibleGuardRule(limit: 9.9),
                BatchedWitnessForecastThresholdRangeRule(min: 1.5, max: 2260.2),
                BatchedWitnessForecastWindowDaysRangeRule(min: 255, max: 255),
                BatchedWitnessForecastTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
