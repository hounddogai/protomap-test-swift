import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession metric must pass. Check returns its problems, or none.
    protocol AccessionMetricRule {
        func check(_ item: AccessionMetric) -> [String]
    }

    final class AccessionMetricBedLengthRule: AccessionMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionMetric) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionMetricNotesLengthRule: AccessionMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionMetric) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionMetricRequiredCodeRule: AccessionMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionMetricTitleLengthRule: AccessionMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionMetricRateRangeRule: AccessionMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionMetric) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionMetricCapacityRangeRule: AccessionMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionMetric) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession metric.
    final class AccessionMetricValidator {
        var rules: [any AccessionMetricRule]

        init(rules: [any AccessionMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionMetric]) -> [String: [String]] {
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

    static func defaultAccessionMetricValidator() -> AccessionMetricValidator {
        return AccessionMetricValidator(
            rules: [
                AccessionMetricBedLengthRule(maxLength: 80),
                AccessionMetricNotesLengthRule(maxLength: 3600),
                AccessionMetricRequiredCodeRule(message: "accession metric needs a value"),
                AccessionMetricTitleLengthRule(maxLength: 120),
                AccessionMetricRateRangeRule(min: 7.5, max: 2793.6),
                AccessionMetricCapacityRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
