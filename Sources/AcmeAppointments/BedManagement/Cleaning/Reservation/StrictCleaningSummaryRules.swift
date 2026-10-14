import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict cleaning summary must pass. Check returns its problems, or none.
    protocol StrictCleaningSummaryRule {
        func check(_ item: StrictCleaningSummary) -> [String]
    }

    final class StrictCleaningSummaryRequiredClinicianIDRule: StrictCleaningSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCleaningSummary) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCleaningSummaryRequiredSummaryRule: StrictCleaningSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCleaningSummary) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCleaningSummaryRateRangeRule: StrictCleaningSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCleaningSummary) -> [String] {
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

    final class StrictCleaningSummaryAllowedReviewerRule: StrictCleaningSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictCleaningSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a strict cleaning summary.
    final class StrictCleaningSummaryValidator {
        var rules: [any StrictCleaningSummaryRule]

        init(rules: [any StrictCleaningSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCleaningSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCleaningSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCleaningSummary]) -> [String: [String]] {
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

    static func defaultStrictCleaningSummaryValidator() -> StrictCleaningSummaryValidator {
        return StrictCleaningSummaryValidator(
            rules: [
                StrictCleaningSummaryRequiredClinicianIDRule(message: "strict cleaning summary needs this field"),
                StrictCleaningSummaryRequiredSummaryRule(message: "strict cleaning summary needs a value"),
                StrictCleaningSummaryRateRangeRule(min: 0.8, max: 4006.7),
                StrictCleaningSummaryAllowedReviewerRule(allowed: ["capped"]),
            ]
        )
    }
}
