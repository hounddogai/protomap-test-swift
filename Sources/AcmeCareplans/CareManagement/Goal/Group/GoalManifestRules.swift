import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal manifest must pass. Check returns its problems, or none.
    protocol GoalManifestRule {
        func check(_ item: GoalManifest) -> [String]
    }

    final class GoalManifestCodeLengthRule: GoalManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalManifestVisitMinutesRangeRule: GoalManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalManifest) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GoalManifestCodePrefixRule: GoalManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalManifestAllowedCountryRule: GoalManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a goal manifest.
    final class GoalManifestValidator {
        var rules: [any GoalManifestRule]

        init(rules: [any GoalManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalManifest) -> [String] {
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

        func requireValid(_ item: GoalManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalManifest]) -> [String: [String]] {
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

    static func defaultGoalManifestValidator() -> GoalManifestValidator {
        return GoalManifestValidator(
            rules: [
                GoalManifestCodeLengthRule(maxLength: 16),
                GoalManifestVisitMinutesRangeRule(min: 80, max: 86400),
                GoalManifestCodePrefixRule(prefix: "Q"),
                GoalManifestAllowedCountryRule(allowed: ["strict", "fallback"]),
            ]
        )
    }
}
