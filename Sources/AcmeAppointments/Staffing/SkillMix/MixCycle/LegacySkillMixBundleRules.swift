import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy skill mix bundle must pass. Check returns its problems, or none.
    protocol LegacySkillMixBundleRule {
        func check(_ item: LegacySkillMixBundle) -> [String]
    }

    final class LegacySkillMixBundleAllowedLabelRule: LegacySkillMixBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacySkillMixBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class LegacySkillMixBundleCeilingRangeRule: LegacySkillMixBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacySkillMixBundle) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacySkillMixBundleRequiredAllergyRule: LegacySkillMixBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySkillMixBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy skill mix bundle.
    final class LegacySkillMixBundleValidator {
        var rules: [any LegacySkillMixBundleRule]

        init(rules: [any LegacySkillMixBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySkillMixBundle) -> [String] {
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

        func requireValid(_ item: LegacySkillMixBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySkillMixBundle]) -> [String: [String]] {
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

    static func defaultLegacySkillMixBundleValidator() -> LegacySkillMixBundleValidator {
        return LegacySkillMixBundleValidator(
            rules: [
                LegacySkillMixBundleAllowedLabelRule(allowed: ["batched", "scheduled"]),
                LegacySkillMixBundleCeilingRangeRule(min: 3.3, max: 4931.6),
                LegacySkillMixBundleRequiredAllergyRule(message: "legacy skill mix bundle needs an entry"),
            ]
        )
    }
}
