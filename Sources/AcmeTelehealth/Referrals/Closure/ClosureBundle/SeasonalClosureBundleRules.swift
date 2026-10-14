import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure bundle must pass. Check returns its problems, or none.
    protocol SeasonalClosureBundleRule {
        func check(_ item: SeasonalClosureBundle) -> [String]
    }

    final class SeasonalClosureBundleAmountRangeRule: SeasonalClosureBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalClosureBundle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalClosureBundleRequiredCategoryRule: SeasonalClosureBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureBundle) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureBundleAllowedLabelRule: SeasonalClosureBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalClosureBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure bundle.
    final class SeasonalClosureBundleValidator {
        var rules: [any SeasonalClosureBundleRule]

        init(rules: [any SeasonalClosureBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureBundle) -> [String] {
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

        func requireValid(_ item: SeasonalClosureBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureBundle]) -> [String: [String]] {
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

    static func defaultSeasonalClosureBundleValidator() -> SeasonalClosureBundleValidator {
        return SeasonalClosureBundleValidator(
            rules: [
                SeasonalClosureBundleAmountRangeRule(min: 8.0, max: 3121.8),
                SeasonalClosureBundleRequiredCategoryRule(message: "seasonal closure bundle needs this field"),
                SeasonalClosureBundleAllowedLabelRule(allowed: ["capped", "fallback", "rolling"]),
            ]
        )
    }
}
