import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient cleaning metric must pass. Check returns its problems, or none.
    protocol LenientCleaningMetricRule {
        func check(_ item: LenientCleaningMetric) -> [String]
    }

    final class LenientCleaningMetricCodeLengthRule: LenientCleaningMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCleaningMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCleaningMetricRequiredTitleRule: LenientCleaningMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCleaningMetricRequiredCodeRule: LenientCleaningMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient cleaning metric.
    final class LenientCleaningMetricValidator {
        var rules: [any LenientCleaningMetricRule]

        init(rules: [any LenientCleaningMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCleaningMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCleaningMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCleaningMetric]) -> [String: [String]] {
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

    static func defaultLenientCleaningMetricValidator() -> LenientCleaningMetricValidator {
        return LenientCleaningMetricValidator(
            rules: [
                LenientCleaningMetricCodeLengthRule(maxLength: 120),
                LenientCleaningMetricRequiredTitleRule(message: "lenient cleaning metric needs an entry"),
                LenientCleaningMetricRequiredCodeRule(message: "lenient cleaning metric needs this field"),
            ]
        )
    }
}
