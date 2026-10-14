import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning metric must pass. Check returns its problems, or none.
    protocol CleaningMetricRule {
        func check(_ item: CleaningMetric) -> [String]
    }

    final class CleaningMetricRequiredNotesRule: CleaningMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningMetric) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningMetricCodeLengthRule: CleaningMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningMetricCeilingRangeRule: CleaningMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningMetric) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningMetricNotesLengthRule: CleaningMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningMetric) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningMetricTitleLengthRule: CleaningMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning metric.
    final class CleaningMetricValidator {
        var rules: [any CleaningMetricRule]

        init(rules: [any CleaningMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningMetric) -> [String] {
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

        func requireValid(_ item: CleaningMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningMetric]) -> [String: [String]] {
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

    static func defaultCleaningMetricValidator() -> CleaningMetricValidator {
        return CleaningMetricValidator(
            rules: [
                CleaningMetricRequiredNotesRule(message: "cleaning metric needs a value"),
                CleaningMetricCodeLengthRule(maxLength: 255),
                CleaningMetricCeilingRangeRule(min: 2.0, max: 955.4),
                CleaningMetricNotesLengthRule(maxLength: 86400),
                CleaningMetricTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
