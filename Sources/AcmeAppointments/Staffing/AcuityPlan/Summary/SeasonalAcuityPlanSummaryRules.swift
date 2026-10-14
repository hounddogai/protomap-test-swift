import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal acuity plan summary must pass. Check returns its problems, or none.
    protocol SeasonalAcuityPlanSummaryRule {
        func check(_ item: SeasonalAcuityPlanSummary) -> [String]
    }

    final class SeasonalAcuityPlanSummaryRequiredSegmentRule: SeasonalAcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAcuityPlanSummary) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanSummaryAllowedCodeRule: SeasonalAcuityPlanSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalAcuityPlanSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanSummaryNameLengthRule: SeasonalAcuityPlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAcuityPlanSummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanSummaryRequiredCodeRule: SeasonalAcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAcuityPlanSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal acuity plan summary.
    final class SeasonalAcuityPlanSummaryValidator {
        var rules: [any SeasonalAcuityPlanSummaryRule]

        init(rules: [any SeasonalAcuityPlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAcuityPlanSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalAcuityPlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAcuityPlanSummary]) -> [String: [String]] {
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

    static func defaultSeasonalAcuityPlanSummaryValidator() -> SeasonalAcuityPlanSummaryValidator {
        return SeasonalAcuityPlanSummaryValidator(
            rules: [
                SeasonalAcuityPlanSummaryRequiredSegmentRule(message: "seasonal acuity plan summary needs this field"),
                SeasonalAcuityPlanSummaryAllowedCodeRule(allowed: []),
                SeasonalAcuityPlanSummaryNameLengthRule(maxLength: 255),
                SeasonalAcuityPlanSummaryRequiredCodeRule(message: "seasonal acuity plan summary needs a value"),
            ]
        )
    }
}
