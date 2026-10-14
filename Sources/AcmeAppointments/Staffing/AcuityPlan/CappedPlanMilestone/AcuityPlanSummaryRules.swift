import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan summary must pass. Check returns its problems, or none.
    protocol AcuityPlanSummaryRule {
        func check(_ item: AcuityPlanSummary) -> [String]
    }

    final class AcuityPlanSummaryCategoryLengthRule: AcuityPlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSummary) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanSummaryCodeLengthRule: AcuityPlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanSummaryRequiredCategoryRule: AcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanSummary) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanSummaryGraceDaysRangeRule: AcuityPlanSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanSummary) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan summary.
    final class AcuityPlanSummaryValidator {
        var rules: [any AcuityPlanSummaryRule]

        init(rules: [any AcuityPlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanSummary) -> [String] {
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

        func requireValid(_ item: AcuityPlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanSummary]) -> [String: [String]] {
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

    static func defaultAcuityPlanSummaryValidator() -> AcuityPlanSummaryValidator {
        return AcuityPlanSummaryValidator(
            rules: [
                AcuityPlanSummaryCategoryLengthRule(maxLength: 1000),
                AcuityPlanSummaryCodeLengthRule(maxLength: 32),
                AcuityPlanSummaryRequiredCategoryRule(message: "acuity plan summary needs this field"),
                AcuityPlanSummaryGraceDaysRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
