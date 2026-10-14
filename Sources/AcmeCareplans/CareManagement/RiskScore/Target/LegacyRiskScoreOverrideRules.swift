import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy risk score override must pass. Check returns its problems, or none.
    protocol LegacyRiskScoreOverrideRule {
        func check(_ item: LegacyRiskScoreOverride) -> [String]
    }

    final class LegacyRiskScoreOverrideRequiredBedRule: LegacyRiskScoreOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRiskScoreOverride) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRiskScoreOverrideTagsLimitRule: LegacyRiskScoreOverrideRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LegacyRiskScoreOverride) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class LegacyRiskScoreOverrideCodeLengthRule: LegacyRiskScoreOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRiskScoreOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRiskScoreOverrideSpecialtyLengthRule: LegacyRiskScoreOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRiskScoreOverride) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRiskScoreOverrideBedLengthRule: LegacyRiskScoreOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRiskScoreOverride) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy risk score override.
    final class LegacyRiskScoreOverrideValidator {
        var rules: [any LegacyRiskScoreOverrideRule]

        init(rules: [any LegacyRiskScoreOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRiskScoreOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRiskScoreOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRiskScoreOverride]) -> [String: [String]] {
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

    static func defaultLegacyRiskScoreOverrideValidator() -> LegacyRiskScoreOverrideValidator {
        return LegacyRiskScoreOverrideValidator(
            rules: [
                LegacyRiskScoreOverrideRequiredBedRule(message: "legacy risk score override needs a value"),
                LegacyRiskScoreOverrideTagsLimitRule(maxCount: 120, banned: ["lenient", "fallback", "seasonal"]),
                LegacyRiskScoreOverrideCodeLengthRule(maxLength: 86400),
                LegacyRiskScoreOverrideSpecialtyLengthRule(maxLength: 86400),
                LegacyRiskScoreOverrideBedLengthRule(maxLength: 120),
            ]
        )
    }
}
