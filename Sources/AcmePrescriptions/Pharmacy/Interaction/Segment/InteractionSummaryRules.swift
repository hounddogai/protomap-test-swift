import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction summary must pass. Check returns its problems, or none.
    protocol InteractionSummaryRule {
        func check(_ item: InteractionSummary) -> [String]
    }

    final class InteractionSummaryMaximumRangeRule: InteractionSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionSummary) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionSummaryTitleLengthRule: InteractionSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionSummaryAllowedCodeRule: InteractionSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction summary.
    final class InteractionSummaryValidator {
        var rules: [any InteractionSummaryRule]

        init(rules: [any InteractionSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionSummary]) -> [String: [String]] {
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

    static func defaultInteractionSummaryValidator() -> InteractionSummaryValidator {
        return InteractionSummaryValidator(
            rules: [
                InteractionSummaryMaximumRangeRule(min: 1.3, max: 4480.6),
                InteractionSummaryTitleLengthRule(maxLength: 120),
                InteractionSummaryAllowedCodeRule(allowed: ["pending", "weighted", "capped"]),
            ]
        )
    }
}
