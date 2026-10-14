import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global skill mix record must pass. Check returns its problems, or none.
    protocol GlobalSkillMixRecordRule {
        func check(_ item: GlobalSkillMixRecord) -> [String]
    }

    final class GlobalSkillMixRecordCodeLengthRule: GlobalSkillMixRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSkillMixRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSkillMixRecordCodePrefixRule: GlobalSkillMixRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalSkillMixRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalSkillMixRecordLabelLengthRule: GlobalSkillMixRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSkillMixRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global skill mix record.
    final class GlobalSkillMixRecordValidator {
        var rules: [any GlobalSkillMixRecordRule]

        init(rules: [any GlobalSkillMixRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSkillMixRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSkillMixRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSkillMixRecord]) -> [String: [String]] {
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

    static func defaultGlobalSkillMixRecordValidator() -> GlobalSkillMixRecordValidator {
        return GlobalSkillMixRecordValidator(
            rules: [
                GlobalSkillMixRecordCodeLengthRule(maxLength: 16),
                GlobalSkillMixRecordCodePrefixRule(prefix: "Q"),
                GlobalSkillMixRecordLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
