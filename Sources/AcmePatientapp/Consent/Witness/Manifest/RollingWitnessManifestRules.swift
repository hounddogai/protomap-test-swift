import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling witness manifest must pass. Check returns its problems, or none.
    protocol RollingWitnessManifestRule {
        func check(_ item: RollingWitnessManifest) -> [String]
    }

    final class RollingWitnessManifestRequiredCodeRule: RollingWitnessManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWitnessManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWitnessManifestTagsLimitRule: RollingWitnessManifestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingWitnessManifest) -> [String] {
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

    final class RollingWitnessManifestCategoryLengthRule: RollingWitnessManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessManifest) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling witness manifest.
    final class RollingWitnessManifestValidator {
        var rules: [any RollingWitnessManifestRule]

        init(rules: [any RollingWitnessManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingWitnessManifest) -> [String] {
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

        func requireValid(_ item: RollingWitnessManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingWitnessManifest]) -> [String: [String]] {
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

    static func defaultRollingWitnessManifestValidator() -> RollingWitnessManifestValidator {
        return RollingWitnessManifestValidator(
            rules: [
                RollingWitnessManifestRequiredCodeRule(message: "rolling witness manifest needs a value"),
                RollingWitnessManifestTagsLimitRule(maxCount: 16, banned: ["seasonal"]),
                RollingWitnessManifestCategoryLengthRule(maxLength: 1000),
            ]
        )
    }
}
