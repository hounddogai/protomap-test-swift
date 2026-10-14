import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional care gap summary must pass. Check returns its problems, or none.
    protocol RegionalCareGapSummaryRule {
        func check(_ item: RegionalCareGapSummary) -> [String]
    }

    final class RegionalCareGapSummaryProcedureCodeLengthRule: RegionalCareGapSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareGapSummary) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareGapSummaryMarginRangeRule: RegionalCareGapSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCareGapSummary) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalCareGapSummaryAllowedLabelRule: RegionalCareGapSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCareGapSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care gap summary.
    final class RegionalCareGapSummaryValidator {
        var rules: [any RegionalCareGapSummaryRule]

        init(rules: [any RegionalCareGapSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareGapSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCareGapSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareGapSummary]) -> [String: [String]] {
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

    static func defaultRegionalCareGapSummaryValidator() -> RegionalCareGapSummaryValidator {
        return RegionalCareGapSummaryValidator(
            rules: [
                RegionalCareGapSummaryProcedureCodeLengthRule(maxLength: 16),
                RegionalCareGapSummaryMarginRangeRule(min: 4.9, max: 851.4),
                RegionalCareGapSummaryAllowedLabelRule(allowed: ["fallback", "capped", "primary"]),
            ]
        )
    }
}
