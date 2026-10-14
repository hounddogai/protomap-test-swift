import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal segment must pass. Check returns its problems, or none.
    protocol GoalSegmentRule {
        func check(_ item: GoalSegment) -> [String]
    }

    final class GoalSegmentCodePrefixRule: GoalSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalSegmentRequiredCountryRule: GoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalSegment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalSegmentTitleLengthRule: GoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalSegmentRequiredContactEmailRule: GoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalSegment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalSegmentAllowedCodeRule: GoalSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a goal segment.
    final class GoalSegmentValidator {
        var rules: [any GoalSegmentRule]

        init(rules: [any GoalSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalSegment) -> [String] {
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

        func requireValid(_ item: GoalSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalSegment]) -> [String: [String]] {
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

    static func defaultGoalSegmentValidator() -> GoalSegmentValidator {
        return GoalSegmentValidator(
            rules: [
                GoalSegmentCodePrefixRule(prefix: "REF"),
                GoalSegmentRequiredCountryRule(message: "goal segment needs this field"),
                GoalSegmentTitleLengthRule(maxLength: 16),
                GoalSegmentRequiredContactEmailRule(message: "goal segment needs a value"),
                GoalSegmentAllowedCodeRule(allowed: ["primary"]),
            ]
        )
    }
}
