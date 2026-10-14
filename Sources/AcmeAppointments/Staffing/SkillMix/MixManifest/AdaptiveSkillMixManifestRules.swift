import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive skill mix manifest must pass. Check returns its problems, or none.
    protocol AdaptiveSkillMixManifestRule {
        func check(_ item: AdaptiveSkillMixManifest) -> [String]
    }

    final class AdaptiveSkillMixManifestTitleLengthRule: AdaptiveSkillMixManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSkillMixManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSkillMixManifestRequiredNameRule: AdaptiveSkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSkillMixManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSkillMixManifestRequiredTitleRule: AdaptiveSkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSkillMixManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSkillMixManifestEndsAtRangeRule: AdaptiveSkillMixManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSkillMixManifest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveSkillMixManifestRequiredCodeRule: AdaptiveSkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSkillMixManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSkillMixManifestApprovedGuardRule: AdaptiveSkillMixManifestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveSkillMixManifest) -> [String] {
            if item.approved && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive skill mix manifest.
    final class AdaptiveSkillMixManifestValidator {
        var rules: [any AdaptiveSkillMixManifestRule]

        init(rules: [any AdaptiveSkillMixManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSkillMixManifest) -> [String] {
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

        func requireValid(_ item: AdaptiveSkillMixManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSkillMixManifest]) -> [String: [String]] {
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

    static func defaultAdaptiveSkillMixManifestValidator() -> AdaptiveSkillMixManifestValidator {
        return AdaptiveSkillMixManifestValidator(
            rules: [
                AdaptiveSkillMixManifestTitleLengthRule(maxLength: 16),
                AdaptiveSkillMixManifestRequiredNameRule(message: "adaptive skill mix manifest needs a value"),
                AdaptiveSkillMixManifestRequiredTitleRule(message: "adaptive skill mix manifest needs this field"),
                AdaptiveSkillMixManifestEndsAtRangeRule(min: 16, max: 16),
                AdaptiveSkillMixManifestRequiredCodeRule(message: "adaptive skill mix manifest needs an entry"),
                AdaptiveSkillMixManifestApprovedGuardRule(limit: 64),
            ]
        )
    }
}
