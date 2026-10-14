import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive courier milestone must pass. Check returns its problems, or none.
    protocol AdaptiveCourierMilestoneRule {
        func check(_ item: AdaptiveCourierMilestone) -> [String]
    }

    final class AdaptiveCourierMilestoneRequiredLabelRule: AdaptiveCourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCourierMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCourierMilestoneBudgetRangeRule: AdaptiveCourierMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCourierMilestone) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveCourierMilestoneAllowedLabelRule: AdaptiveCourierMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCourierMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class AdaptiveCourierMilestoneCodeLengthRule: AdaptiveCourierMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCourierMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive courier milestone.
    final class AdaptiveCourierMilestoneValidator {
        var rules: [any AdaptiveCourierMilestoneRule]

        init(rules: [any AdaptiveCourierMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCourierMilestone) -> [String] {
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

        func requireValid(_ item: AdaptiveCourierMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCourierMilestone]) -> [String: [String]] {
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

    static func defaultAdaptiveCourierMilestoneValidator() -> AdaptiveCourierMilestoneValidator {
        return AdaptiveCourierMilestoneValidator(
            rules: [
                AdaptiveCourierMilestoneRequiredLabelRule(message: "adaptive courier milestone needs a value"),
                AdaptiveCourierMilestoneBudgetRangeRule(min: 2.2, max: 3401.5),
                AdaptiveCourierMilestoneAllowedLabelRule(allowed: ["manual"]),
                AdaptiveCourierMilestoneCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
