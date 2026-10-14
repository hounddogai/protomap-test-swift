import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study tier must pass. Check returns its problems, or none.
    protocol StudyTierRule {
        func check(_ item: StudyTier) -> [String]
    }

    final class StudyTierAllowedSummaryRule: StudyTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is duplicated"]
            }
            return []
        }
    }

    final class StudyTierStartsAtRangeRule: StudyTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyTier) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyTierCodePrefixRule: StudyTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StudyTierRequiredFacilityRule: StudyTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyTier) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study tier.
    final class StudyTierValidator {
        var rules: [any StudyTierRule]

        init(rules: [any StudyTierRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyTier) -> [String] {
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

        func requireValid(_ item: StudyTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyTier]) -> [String: [String]] {
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

    static func defaultStudyTierValidator() -> StudyTierValidator {
        return StudyTierValidator(
            rules: [
                StudyTierAllowedSummaryRule(allowed: ["manual"]),
                StudyTierStartsAtRangeRule(min: 16, max: 120),
                StudyTierCodePrefixRule(prefix: "REF"),
                StudyTierRequiredFacilityRule(message: "study tier needs this field"),
            ]
        )
    }
}
