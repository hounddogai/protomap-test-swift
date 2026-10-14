import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary skill mix manifest must pass. Check returns its problems, or none.
    protocol PrimarySkillMixManifestRule {
        func check(_ item: PrimarySkillMixManifest) -> [String]
    }

    final class PrimarySkillMixManifestUnitLengthRule: PrimarySkillMixManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySkillMixManifest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySkillMixManifestRequiredUnitRule: PrimarySkillMixManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySkillMixManifest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySkillMixManifestTitleLengthRule: PrimarySkillMixManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySkillMixManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySkillMixManifestAcuityRangeRule: PrimarySkillMixManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySkillMixManifest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimarySkillMixManifestCodeLengthRule: PrimarySkillMixManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySkillMixManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary skill mix manifest.
    final class PrimarySkillMixManifestValidator {
        var rules: [any PrimarySkillMixManifestRule]

        init(rules: [any PrimarySkillMixManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySkillMixManifest) -> [String] {
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

        func requireValid(_ item: PrimarySkillMixManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySkillMixManifest]) -> [String: [String]] {
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

    static func defaultPrimarySkillMixManifestValidator() -> PrimarySkillMixManifestValidator {
        return PrimarySkillMixManifestValidator(
            rules: [
                PrimarySkillMixManifestUnitLengthRule(maxLength: 3600),
                PrimarySkillMixManifestRequiredUnitRule(message: "primary skill mix manifest needs an entry"),
                PrimarySkillMixManifestTitleLengthRule(maxLength: 86400),
                PrimarySkillMixManifestAcuityRangeRule(min: 255, max: 3600),
                PrimarySkillMixManifestCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
