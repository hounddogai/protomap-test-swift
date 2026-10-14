import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending accession metric must pass. Check returns its problems, or none.
    protocol PendingAccessionMetricRule {
        func check(_ item: PendingAccessionMetric) -> [String]
    }

    final class PendingAccessionMetricNotesLengthRule: PendingAccessionMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAccessionMetric) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAccessionMetricRequiredCodeRule: PendingAccessionMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAccessionMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAccessionMetricVersionRangeRule: PendingAccessionMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAccessionMetric) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingAccessionMetricLabelLengthRule: PendingAccessionMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAccessionMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending accession metric.
    final class PendingAccessionMetricValidator {
        var rules: [any PendingAccessionMetricRule]

        init(rules: [any PendingAccessionMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAccessionMetric) -> [String] {
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

        func requireValid(_ item: PendingAccessionMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAccessionMetric]) -> [String: [String]] {
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

    static func defaultPendingAccessionMetricValidator() -> PendingAccessionMetricValidator {
        return PendingAccessionMetricValidator(
            rules: [
                PendingAccessionMetricNotesLengthRule(maxLength: 32),
                PendingAccessionMetricRequiredCodeRule(message: "pending accession metric needs a value"),
                PendingAccessionMetricVersionRangeRule(min: 80, max: 1000),
                PendingAccessionMetricLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
