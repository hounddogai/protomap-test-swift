import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal skill mix segment must pass. Check returns its problems, or none.
    protocol SeasonalSkillMixSegmentRule {
        func check(_ item: SeasonalSkillMixSegment) -> [String]
    }

    final class SeasonalSkillMixSegmentDurationMinutesRangeRule: SeasonalSkillMixSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixSegment) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixSegmentRequiredCodeRule: SeasonalSkillMixSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixSegmentAllowedAllergyRule: SeasonalSkillMixSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSkillMixSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is too long"]
            }
            return []
        }
    }

    final class SeasonalSkillMixSegmentNameLengthRule: SeasonalSkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixSegmentCategoryLengthRule: SeasonalSkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixSegment) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixSegmentAllergyLengthRule: SeasonalSkillMixSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixSegment) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal skill mix segment.
    final class SeasonalSkillMixSegmentValidator {
        var rules: [any SeasonalSkillMixSegmentRule]

        init(rules: [any SeasonalSkillMixSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSkillMixSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSkillMixSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSkillMixSegment]) -> [String: [String]] {
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

    static func defaultSeasonalSkillMixSegmentValidator() -> SeasonalSkillMixSegmentValidator {
        return SeasonalSkillMixSegmentValidator(
            rules: [
                SeasonalSkillMixSegmentDurationMinutesRangeRule(min: 1000, max: 86400),
                SeasonalSkillMixSegmentRequiredCodeRule(message: "seasonal skill mix segment needs this field"),
                SeasonalSkillMixSegmentAllowedAllergyRule(allowed: ["adaptive", "manual", "default"]),
                SeasonalSkillMixSegmentNameLengthRule(maxLength: 32),
                SeasonalSkillMixSegmentCategoryLengthRule(maxLength: 32),
                SeasonalSkillMixSegmentAllergyLengthRule(maxLength: 255),
            ]
        )
    }
}
