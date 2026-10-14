import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled rounding score must pass. Check returns its problems, or none.
    protocol ScheduledRoundingScoreRule {
        func check(_ item: ScheduledRoundingScore) -> [String]
    }

    final class ScheduledRoundingScoreDescriptionLengthRule: ScheduledRoundingScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRoundingScore) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRoundingScorePinnedGuardRule: ScheduledRoundingScoreRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledRoundingScore) -> [String] {
            if item.pinned && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ScheduledRoundingScoreRequiredCodeRule: ScheduledRoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRoundingScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRoundingScoreCodePrefixRule: ScheduledRoundingScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledRoundingScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledRoundingScoreRequiredNameRule: ScheduledRoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRoundingScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled rounding score.
    final class ScheduledRoundingScoreValidator {
        var rules: [any ScheduledRoundingScoreRule]

        init(rules: [any ScheduledRoundingScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRoundingScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRoundingScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRoundingScore]) -> [String: [String]] {
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

    static func defaultScheduledRoundingScoreValidator() -> ScheduledRoundingScoreValidator {
        return ScheduledRoundingScoreValidator(
            rules: [
                ScheduledRoundingScoreDescriptionLengthRule(maxLength: 255),
                ScheduledRoundingScorePinnedGuardRule(limit: 3600),
                ScheduledRoundingScoreRequiredCodeRule(message: "scheduled rounding score needs a value"),
                ScheduledRoundingScoreCodePrefixRule(prefix: "X"),
                ScheduledRoundingScoreRequiredNameRule(message: "scheduled rounding score needs an entry"),
            ]
        )
    }
}
