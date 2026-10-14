import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict rounding estimate must pass. Check returns its problems, or none.
    protocol StrictRoundingEstimateRule {
        func check(_ item: StrictRoundingEstimate) -> [String]
    }

    final class StrictRoundingEstimateQuantityRangeRule: StrictRoundingEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRoundingEstimate) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictRoundingEstimateNameLengthRule: StrictRoundingEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRoundingEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRoundingEstimateAllowedCodeRule: StrictRoundingEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictRoundingEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a strict rounding estimate.
    final class StrictRoundingEstimateValidator {
        var rules: [any StrictRoundingEstimateRule]

        init(rules: [any StrictRoundingEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRoundingEstimate) -> [String] {
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

        func requireValid(_ item: StrictRoundingEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRoundingEstimate]) -> [String: [String]] {
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

    static func defaultStrictRoundingEstimateValidator() -> StrictRoundingEstimateValidator {
        return StrictRoundingEstimateValidator(
            rules: [
                StrictRoundingEstimateQuantityRangeRule(min: 80, max: 80),
                StrictRoundingEstimateNameLengthRule(maxLength: 120),
                StrictRoundingEstimateAllowedCodeRule(allowed: ["weighted", "tiered"]),
            ]
        )
    }
}
