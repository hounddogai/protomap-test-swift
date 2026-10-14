import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback float pool milestone must pass. Check returns its problems, or none.
    protocol FallbackFloatPoolMilestoneRule {
        func check(_ item: FallbackFloatPoolMilestone) -> [String]
    }

    final class FallbackFloatPoolMilestoneAllowedCodeRule: FallbackFloatPoolMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackFloatPoolMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class FallbackFloatPoolMilestoneCodeLengthRule: FallbackFloatPoolMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFloatPoolMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolMilestoneRequiredCodeRule: FallbackFloatPoolMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFloatPoolMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackFloatPoolMilestoneRequiredReviewerRule: FallbackFloatPoolMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFloatPoolMilestone) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback float pool milestone.
    final class FallbackFloatPoolMilestoneValidator {
        var rules: [any FallbackFloatPoolMilestoneRule]

        init(rules: [any FallbackFloatPoolMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFloatPoolMilestone) -> [String] {
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

        func requireValid(_ item: FallbackFloatPoolMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFloatPoolMilestone]) -> [String: [String]] {
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

    static func defaultFallbackFloatPoolMilestoneValidator() -> FallbackFloatPoolMilestoneValidator {
        return FallbackFloatPoolMilestoneValidator(
            rules: [
                FallbackFloatPoolMilestoneAllowedCodeRule(allowed: ["global", "fallback", "adaptive"]),
                FallbackFloatPoolMilestoneCodeLengthRule(maxLength: 80),
                FallbackFloatPoolMilestoneRequiredCodeRule(message: "fallback float pool milestone needs an entry"),
                FallbackFloatPoolMilestoneRequiredReviewerRule(
                    message: "fallback float pool milestone needs an entry"
                ),
            ]
        )
    }
}
