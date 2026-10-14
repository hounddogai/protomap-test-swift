import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default skill mix record must pass. Check returns its problems, or none.
    protocol DefaultSkillMixRecordRule {
        func check(_ item: DefaultSkillMixRecord) -> [String]
    }

    final class DefaultSkillMixRecordTimezoneLengthRule: DefaultSkillMixRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSkillMixRecord) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSkillMixRecordLabelLengthRule: DefaultSkillMixRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSkillMixRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSkillMixRecordAllowedLabelRule: DefaultSkillMixRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultSkillMixRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class DefaultSkillMixRecordCodePrefixRule: DefaultSkillMixRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSkillMixRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultSkillMixRecordStartsAtRangeRule: DefaultSkillMixRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSkillMixRecord) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultSkillMixRecordRequiredLabelRule: DefaultSkillMixRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSkillMixRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default skill mix record.
    final class DefaultSkillMixRecordValidator {
        var rules: [any DefaultSkillMixRecordRule]

        init(rules: [any DefaultSkillMixRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSkillMixRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultSkillMixRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSkillMixRecord]) -> [String: [String]] {
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

    static func defaultDefaultSkillMixRecordValidator() -> DefaultSkillMixRecordValidator {
        return DefaultSkillMixRecordValidator(
            rules: [
                DefaultSkillMixRecordTimezoneLengthRule(maxLength: 64),
                DefaultSkillMixRecordLabelLengthRule(maxLength: 80),
                DefaultSkillMixRecordAllowedLabelRule(allowed: ["adaptive", "strict"]),
                DefaultSkillMixRecordCodePrefixRule(prefix: "Q"),
                DefaultSkillMixRecordStartsAtRangeRule(min: 80, max: 3600),
                DefaultSkillMixRecordRequiredLabelRule(message: "default skill mix record needs a value"),
            ]
        )
    }
}
