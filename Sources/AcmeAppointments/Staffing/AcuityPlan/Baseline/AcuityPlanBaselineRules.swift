import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan baseline must pass. Check returns its problems, or none.
    protocol AcuityPlanBaselineRule {
        func check(_ item: AcuityPlanBaseline) -> [String]
    }

    final class AcuityPlanBaselineRequiredSummaryRule: AcuityPlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanBaseline) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanBaselineCodeLengthRule: AcuityPlanBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanBaselineTitleLengthRule: AcuityPlanBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanBaselineRateRangeRule: AcuityPlanBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanBaseline) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan baseline.
    final class AcuityPlanBaselineValidator {
        var rules: [any AcuityPlanBaselineRule]

        init(rules: [any AcuityPlanBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanBaseline) -> [String] {
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

        func requireValid(_ item: AcuityPlanBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanBaseline]) -> [String: [String]] {
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

    static func defaultAcuityPlanBaselineValidator() -> AcuityPlanBaselineValidator {
        return AcuityPlanBaselineValidator(
            rules: [
                AcuityPlanBaselineRequiredSummaryRule(message: "acuity plan baseline needs a value"),
                AcuityPlanBaselineCodeLengthRule(maxLength: 80),
                AcuityPlanBaselineTitleLengthRule(maxLength: 32),
                AcuityPlanBaselineRateRangeRule(min: 2.0, max: 143.2),
            ]
        )
    }
}
