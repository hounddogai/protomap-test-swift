import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal order set profile must pass. Check returns its problems, or none.
    protocol SeasonalOrderSetProfileRule {
        func check(_ item: SeasonalOrderSetProfile) -> [String]
    }

    final class SeasonalOrderSetProfileRevisionRangeRule: SeasonalOrderSetProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalOrderSetProfile) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalOrderSetProfileLabelLengthRule: SeasonalOrderSetProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetProfileCategoryLengthRule: SeasonalOrderSetProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetProfile) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetProfileAllowedFacilityRule: SeasonalOrderSetProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalOrderSetProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal order set profile.
    final class SeasonalOrderSetProfileValidator {
        var rules: [any SeasonalOrderSetProfileRule]

        init(rules: [any SeasonalOrderSetProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOrderSetProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalOrderSetProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOrderSetProfile]) -> [String: [String]] {
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

    static func defaultSeasonalOrderSetProfileValidator() -> SeasonalOrderSetProfileValidator {
        return SeasonalOrderSetProfileValidator(
            rules: [
                SeasonalOrderSetProfileRevisionRangeRule(min: 16, max: 120),
                SeasonalOrderSetProfileLabelLengthRule(maxLength: 1000),
                SeasonalOrderSetProfileCategoryLengthRule(maxLength: 3600),
                SeasonalOrderSetProfileAllowedFacilityRule(allowed: []),
            ]
        )
    }
}
