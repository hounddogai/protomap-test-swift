import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal skill mix manifest must pass. Check returns its problems, or none.
    protocol SeasonalSkillMixManifestRule {
        func check(_ item: SeasonalSkillMixManifest) -> [String]
    }

    final class SeasonalSkillMixManifestRequiredSourceRule: SeasonalSkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixManifest) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixManifestAllowedPatientRefRule: SeasonalSkillMixManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSkillMixManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is missing"]
            }
            return []
        }
    }

    final class SeasonalSkillMixManifestRequiredCodeRule: SeasonalSkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixManifestRequiredPatientRefRule: SeasonalSkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixManifest) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal skill mix manifest.
    final class SeasonalSkillMixManifestValidator {
        var rules: [any SeasonalSkillMixManifestRule]

        init(rules: [any SeasonalSkillMixManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSkillMixManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSkillMixManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSkillMixManifest]) -> [String: [String]] {
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

    static func defaultSeasonalSkillMixManifestValidator() -> SeasonalSkillMixManifestValidator {
        return SeasonalSkillMixManifestValidator(
            rules: [
                SeasonalSkillMixManifestRequiredSourceRule(message: "seasonal skill mix manifest needs this field"),
                SeasonalSkillMixManifestAllowedPatientRefRule(allowed: ["pending", "scheduled", "seasonal"]),
                SeasonalSkillMixManifestRequiredCodeRule(message: "seasonal skill mix manifest needs this field"),
                SeasonalSkillMixManifestRequiredPatientRefRule(message: "seasonal skill mix manifest needs a value"),
            ]
        )
    }
}
