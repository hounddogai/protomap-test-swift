import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary specimen metric must pass. Check returns its problems, or none.
    protocol PrimarySpecimenMetricRule {
        func check(_ item: PrimarySpecimenMetric) -> [String]
    }

    final class PrimarySpecimenMetricRequiredSummaryRule: PrimarySpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySpecimenMetric) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySpecimenMetricRequiredLabelRule: PrimarySpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySpecimenMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySpecimenMetricCodeLengthRule: PrimarySpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySpecimenMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySpecimenMetricSummaryLengthRule: PrimarySpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySpecimenMetric) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary specimen metric.
    final class PrimarySpecimenMetricValidator {
        var rules: [any PrimarySpecimenMetricRule]

        init(rules: [any PrimarySpecimenMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySpecimenMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimarySpecimenMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySpecimenMetric]) -> [String: [String]] {
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

    static func defaultPrimarySpecimenMetricValidator() -> PrimarySpecimenMetricValidator {
        return PrimarySpecimenMetricValidator(
            rules: [
                PrimarySpecimenMetricRequiredSummaryRule(message: "primary specimen metric needs this field"),
                PrimarySpecimenMetricRequiredLabelRule(message: "primary specimen metric needs an entry"),
                PrimarySpecimenMetricCodeLengthRule(maxLength: 1000),
                PrimarySpecimenMetricSummaryLengthRule(maxLength: 32),
            ]
        )
    }
}
