import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual care gap summary must pass. Check returns its problems, or none.
    protocol ManualCareGapSummaryRule {
        func check(_ item: ManualCareGapSummary) -> [String]
    }

    final class ManualCareGapSummarySummaryLengthRule: ManualCareGapSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapSummary) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapSummaryRequiredCountryRule: ManualCareGapSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareGapSummary) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareGapSummaryCountryLengthRule: ManualCareGapSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapSummary) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapSummaryAcuityRangeRule: ManualCareGapSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCareGapSummary) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualCareGapSummaryAllowedSummaryRule: ManualCareGapSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCareGapSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is unknown"]
            }
            return []
        }
    }

    final class ManualCareGapSummaryCodeLengthRule: ManualCareGapSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual care gap summary.
    final class ManualCareGapSummaryValidator {
        var rules: [any ManualCareGapSummaryRule]

        init(rules: [any ManualCareGapSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareGapSummary) -> [String] {
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

        func requireValid(_ item: ManualCareGapSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareGapSummary]) -> [String: [String]] {
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

    static func defaultManualCareGapSummaryValidator() -> ManualCareGapSummaryValidator {
        return ManualCareGapSummaryValidator(
            rules: [
                ManualCareGapSummarySummaryLengthRule(maxLength: 1000),
                ManualCareGapSummaryRequiredCountryRule(message: "manual care gap summary needs this field"),
                ManualCareGapSummaryCountryLengthRule(maxLength: 120),
                ManualCareGapSummaryAcuityRangeRule(min: 16, max: 1000),
                ManualCareGapSummaryAllowedSummaryRule(allowed: ["legacy", "default"]),
                ManualCareGapSummaryCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
