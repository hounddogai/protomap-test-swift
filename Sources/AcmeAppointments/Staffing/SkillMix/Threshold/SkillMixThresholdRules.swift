import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix threshold must pass. Check returns its problems, or none.
    protocol SkillMixThresholdRule {
        func check(_ item: SkillMixThreshold) -> [String]
    }

    final class SkillMixThresholdRequiredTitleRule: SkillMixThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixThresholdAllowedChannelRule: SkillMixThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is not allowed"]
            }
            return []
        }
    }

    final class SkillMixThresholdCodeLengthRule: SkillMixThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixThresholdEncounterIDLengthRule: SkillMixThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixThreshold) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix threshold.
    final class SkillMixThresholdValidator {
        var rules: [any SkillMixThresholdRule]

        init(rules: [any SkillMixThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixThreshold]) -> [String: [String]] {
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

    static func defaultSkillMixThresholdValidator() -> SkillMixThresholdValidator {
        return SkillMixThresholdValidator(
            rules: [
                SkillMixThresholdRequiredTitleRule(message: "skill mix threshold needs a value"),
                SkillMixThresholdAllowedChannelRule(allowed: ["adaptive"]),
                SkillMixThresholdCodeLengthRule(maxLength: 80),
                SkillMixThresholdEncounterIDLengthRule(maxLength: 3600),
            ]
        )
    }
}
