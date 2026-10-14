import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy assessment milestone must pass. Check returns its problems, or none.
    protocol LegacyAssessmentMilestoneRule {
        func check(_ item: LegacyAssessmentMilestone) -> [String]
    }

    final class LegacyAssessmentMilestoneRequiredNameRule: LegacyAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentMilestoneNameLengthRule: LegacyAssessmentMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAssessmentMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAssessmentMilestoneRequiredDescriptionRule: LegacyAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentMilestone) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentMilestoneRequiredCodeRule: LegacyAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentMilestoneRequiredChecksumRule: LegacyAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentMilestone) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentMilestoneAllowedCodeRule: LegacyAssessmentMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAssessmentMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy assessment milestone.
    final class LegacyAssessmentMilestoneValidator {
        var rules: [any LegacyAssessmentMilestoneRule]

        init(rules: [any LegacyAssessmentMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAssessmentMilestone) -> [String] {
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

        func requireValid(_ item: LegacyAssessmentMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAssessmentMilestone]) -> [String: [String]] {
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

    static func defaultLegacyAssessmentMilestoneValidator() -> LegacyAssessmentMilestoneValidator {
        return LegacyAssessmentMilestoneValidator(
            rules: [
                LegacyAssessmentMilestoneRequiredNameRule(message: "legacy assessment milestone needs this field"),
                LegacyAssessmentMilestoneNameLengthRule(maxLength: 16),
                LegacyAssessmentMilestoneRequiredDescriptionRule(
                    message: "legacy assessment milestone needs this field"
                ),
                LegacyAssessmentMilestoneRequiredCodeRule(message: "legacy assessment milestone needs a value"),
                LegacyAssessmentMilestoneRequiredChecksumRule(message: "legacy assessment milestone needs an entry"),
                LegacyAssessmentMilestoneAllowedCodeRule(allowed: ["global"]),
            ]
        )
    }
}
