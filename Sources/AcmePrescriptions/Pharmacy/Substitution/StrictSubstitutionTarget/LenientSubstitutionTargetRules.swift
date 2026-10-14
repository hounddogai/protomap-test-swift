import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient substitution target must pass. Check returns its problems, or none.
    protocol LenientSubstitutionTargetRule {
        func check(_ item: LenientSubstitutionTarget) -> [String]
    }

    final class LenientSubstitutionTargetRequiredNameRule: LenientSubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSubstitutionTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSubstitutionTargetFloorValueRangeRule: LenientSubstitutionTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSubstitutionTarget) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientSubstitutionTargetExpiresAtRangeRule: LenientSubstitutionTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSubstitutionTarget) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientSubstitutionTargetCodePrefixRule: LenientSubstitutionTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientSubstitutionTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient substitution target.
    final class LenientSubstitutionTargetValidator {
        var rules: [any LenientSubstitutionTargetRule]

        init(rules: [any LenientSubstitutionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSubstitutionTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSubstitutionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSubstitutionTarget]) -> [String: [String]] {
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

    static func defaultLenientSubstitutionTargetValidator() -> LenientSubstitutionTargetValidator {
        return LenientSubstitutionTargetValidator(
            rules: [
                LenientSubstitutionTargetRequiredNameRule(message: "lenient substitution target needs this field"),
                LenientSubstitutionTargetFloorValueRangeRule(min: 6.4, max: 2160.9),
                LenientSubstitutionTargetExpiresAtRangeRule(min: 32, max: 64),
                LenientSubstitutionTargetCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
