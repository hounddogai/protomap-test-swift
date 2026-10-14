import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted substitution profile must pass. Check returns its problems, or none.
    protocol WeightedSubstitutionProfileRule {
        func check(_ item: WeightedSubstitutionProfile) -> [String]
    }

    final class WeightedSubstitutionProfileAmountRangeRule: WeightedSubstitutionProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSubstitutionProfile) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionProfileAllowedTitleRule: WeightedSubstitutionProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedSubstitutionProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class WeightedSubstitutionProfileCodeLengthRule: WeightedSubstitutionProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSubstitutionProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted substitution profile.
    final class WeightedSubstitutionProfileValidator {
        var rules: [any WeightedSubstitutionProfileRule]

        init(rules: [any WeightedSubstitutionProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSubstitutionProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedSubstitutionProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSubstitutionProfile]) -> [String: [String]] {
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

    static func defaultWeightedSubstitutionProfileValidator() -> WeightedSubstitutionProfileValidator {
        return WeightedSubstitutionProfileValidator(
            rules: [
                WeightedSubstitutionProfileAmountRangeRule(min: 2.5, max: 3497.5),
                WeightedSubstitutionProfileAllowedTitleRule(allowed: ["global", "manual"]),
                WeightedSubstitutionProfileCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
