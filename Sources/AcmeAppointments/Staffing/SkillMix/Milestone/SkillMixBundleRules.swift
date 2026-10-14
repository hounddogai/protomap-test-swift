import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix bundle must pass. Check returns its problems, or none.
    protocol SkillMixBundleRule {
        func check(_ item: SkillMixBundle) -> [String]
    }

    final class SkillMixBundleLocaleLengthRule: SkillMixBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixBundle) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixBundleAllowedTitleRule: SkillMixBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class SkillMixBundleRequiredCodeRule: SkillMixBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixBundleTitleLengthRule: SkillMixBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixBundleRequiredNameRule: SkillMixBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix bundle.
    final class SkillMixBundleValidator {
        var rules: [any SkillMixBundleRule]

        init(rules: [any SkillMixBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixBundle]) -> [String: [String]] {
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

    static func defaultSkillMixBundleValidator() -> SkillMixBundleValidator {
        return SkillMixBundleValidator(
            rules: [
                SkillMixBundleLocaleLengthRule(maxLength: 255),
                SkillMixBundleAllowedTitleRule(allowed: []),
                SkillMixBundleRequiredCodeRule(message: "skill mix bundle needs a value"),
                SkillMixBundleTitleLengthRule(maxLength: 32),
                SkillMixBundleRequiredNameRule(message: "skill mix bundle needs an entry"),
            ]
        )
    }
}
