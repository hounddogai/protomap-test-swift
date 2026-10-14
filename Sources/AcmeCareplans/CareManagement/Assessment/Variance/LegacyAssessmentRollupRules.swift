import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy assessment rollup must pass. Check returns its problems, or none.
    protocol LegacyAssessmentRollupRule {
        func check(_ item: LegacyAssessmentRollup) -> [String]
    }

    final class LegacyAssessmentRollupAllowedCodeRule: LegacyAssessmentRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAssessmentRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class LegacyAssessmentRollupRequiredCodeRule: LegacyAssessmentRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentRollupLabelLengthRule: LegacyAssessmentRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAssessmentRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAssessmentRollupRequiredDescriptionRule: LegacyAssessmentRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentRollup) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentRollupRequiredLabelRule: LegacyAssessmentRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy assessment rollup.
    final class LegacyAssessmentRollupValidator {
        var rules: [any LegacyAssessmentRollupRule]

        init(rules: [any LegacyAssessmentRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAssessmentRollup) -> [String] {
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

        func requireValid(_ item: LegacyAssessmentRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAssessmentRollup]) -> [String: [String]] {
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

    static func defaultLegacyAssessmentRollupValidator() -> LegacyAssessmentRollupValidator {
        return LegacyAssessmentRollupValidator(
            rules: [
                LegacyAssessmentRollupAllowedCodeRule(allowed: ["pending", "pending"]),
                LegacyAssessmentRollupRequiredCodeRule(message: "legacy assessment rollup needs an entry"),
                LegacyAssessmentRollupLabelLengthRule(maxLength: 80),
                LegacyAssessmentRollupRequiredDescriptionRule(message: "legacy assessment rollup needs this field"),
                LegacyAssessmentRollupRequiredLabelRule(message: "legacy assessment rollup needs this field"),
            ]
        )
    }
}
