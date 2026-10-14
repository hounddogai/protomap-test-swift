import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal acuity plan bundle must pass. Check returns its problems, or none.
    protocol SeasonalAcuityPlanBundleRule {
        func check(_ item: SeasonalAcuityPlanBundle) -> [String]
    }

    final class SeasonalAcuityPlanBundleNameLengthRule: SeasonalAcuityPlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAcuityPlanBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanBundleRefillsRangeRule: SeasonalAcuityPlanBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAcuityPlanBundle) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalAcuityPlanBundleRequiredCodeRule: SeasonalAcuityPlanBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAcuityPlanBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanBundleCategoryLengthRule: SeasonalAcuityPlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAcuityPlanBundle) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanBundleRequiredNameRule: SeasonalAcuityPlanBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAcuityPlanBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal acuity plan bundle.
    final class SeasonalAcuityPlanBundleValidator {
        var rules: [any SeasonalAcuityPlanBundleRule]

        init(rules: [any SeasonalAcuityPlanBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAcuityPlanBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalAcuityPlanBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAcuityPlanBundle]) -> [String: [String]] {
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

    static func defaultSeasonalAcuityPlanBundleValidator() -> SeasonalAcuityPlanBundleValidator {
        return SeasonalAcuityPlanBundleValidator(
            rules: [
                SeasonalAcuityPlanBundleNameLengthRule(maxLength: 120),
                SeasonalAcuityPlanBundleRefillsRangeRule(min: 32, max: 120),
                SeasonalAcuityPlanBundleRequiredCodeRule(message: "seasonal acuity plan bundle needs this field"),
                SeasonalAcuityPlanBundleCategoryLengthRule(maxLength: 16),
                SeasonalAcuityPlanBundleRequiredNameRule(message: "seasonal acuity plan bundle needs an entry"),
            ]
        )
    }
}
