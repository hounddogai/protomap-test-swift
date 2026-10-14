import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict worklist metric must pass. Check returns its problems, or none.
    protocol StrictWorklistMetricRule {
        func check(_ item: StrictWorklistMetric) -> [String]
    }

    final class StrictWorklistMetricRequiredTitleRule: StrictWorklistMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWorklistMetricDescriptionLengthRule: StrictWorklistMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWorklistMetric) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWorklistMetricRequiredDescriptionRule: StrictWorklistMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistMetric) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWorklistMetricCodePrefixRule: StrictWorklistMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictWorklistMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict worklist metric.
    final class StrictWorklistMetricValidator {
        var rules: [any StrictWorklistMetricRule]

        init(rules: [any StrictWorklistMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWorklistMetric) -> [String] {
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

        func requireValid(_ item: StrictWorklistMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWorklistMetric]) -> [String: [String]] {
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

    static func defaultStrictWorklistMetricValidator() -> StrictWorklistMetricValidator {
        return StrictWorklistMetricValidator(
            rules: [
                StrictWorklistMetricRequiredTitleRule(message: "strict worklist metric needs this field"),
                StrictWorklistMetricDescriptionLengthRule(maxLength: 3600),
                StrictWorklistMetricRequiredDescriptionRule(message: "strict worklist metric needs an entry"),
                StrictWorklistMetricCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
