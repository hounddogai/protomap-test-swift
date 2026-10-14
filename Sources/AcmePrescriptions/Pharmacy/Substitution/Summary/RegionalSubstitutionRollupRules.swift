import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional substitution rollup must pass. Check returns its problems, or none.
    protocol RegionalSubstitutionRollupRule {
        func check(_ item: RegionalSubstitutionRollup) -> [String]
    }

    final class RegionalSubstitutionRollupAllowedCodeRule: RegionalSubstitutionRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSubstitutionRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class RegionalSubstitutionRollupRequiredCodeRule: RegionalSubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSubstitutionRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSubstitutionRollupRegionLengthRule: RegionalSubstitutionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSubstitutionRollup) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSubstitutionRollupCeilingRangeRule: RegionalSubstitutionRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSubstitutionRollup) -> [String] {
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

    final class RegionalSubstitutionRollupBatchSizeRangeRule: RegionalSubstitutionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSubstitutionRollup) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalSubstitutionRollupCodeLengthRule: RegionalSubstitutionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSubstitutionRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional substitution rollup.
    final class RegionalSubstitutionRollupValidator {
        var rules: [any RegionalSubstitutionRollupRule]

        init(rules: [any RegionalSubstitutionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSubstitutionRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSubstitutionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSubstitutionRollup]) -> [String: [String]] {
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

    static func defaultRegionalSubstitutionRollupValidator() -> RegionalSubstitutionRollupValidator {
        return RegionalSubstitutionRollupValidator(
            rules: [
                RegionalSubstitutionRollupAllowedCodeRule(allowed: ["regional", "seasonal", "global"]),
                RegionalSubstitutionRollupRequiredCodeRule(message: "regional substitution rollup needs a value"),
                RegionalSubstitutionRollupRegionLengthRule(maxLength: 64),
                RegionalSubstitutionRollupCeilingRangeRule(min: 7.6, max: 660.5),
                RegionalSubstitutionRollupBatchSizeRangeRule(min: 1000, max: 86400),
                RegionalSubstitutionRollupCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
