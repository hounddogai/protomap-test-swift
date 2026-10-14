import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study baseline must pass. Check returns its problems, or none.
    protocol StudyBaselineRule {
        func check(_ item: StudyBaseline) -> [String]
    }

    final class StudyBaselineRateRangeRule: StudyBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyBaseline) -> [String] {
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

    final class StudyBaselineRequiredCodeRule: StudyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyBaselineRequiredLabelRule: StudyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study baseline.
    final class StudyBaselineValidator {
        var rules: [any StudyBaselineRule]

        init(rules: [any StudyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyBaseline) -> [String] {
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

        func requireValid(_ item: StudyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyBaseline]) -> [String: [String]] {
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

    static func defaultStudyBaselineValidator() -> StudyBaselineValidator {
        return StudyBaselineValidator(
            rules: [
                StudyBaselineRateRangeRule(min: 5.3, max: 442.7),
                StudyBaselineRequiredCodeRule(message: "study baseline needs a value"),
                StudyBaselineRequiredLabelRule(message: "study baseline needs this field"),
            ]
        )
    }
}
