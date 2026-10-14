import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient substitution rollup must pass. Check returns its problems, or none.
    protocol LenientSubstitutionRollupRule {
        func check(_ item: LenientSubstitutionRollup) -> [String]
    }

    final class LenientSubstitutionRollupCodePrefixRule: LenientSubstitutionRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientSubstitutionRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientSubstitutionRollupFloorValueRangeRule: LenientSubstitutionRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSubstitutionRollup) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientSubstitutionRollupRequiredLabelRule: LenientSubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSubstitutionRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSubstitutionRollupGraceDaysRangeRule: LenientSubstitutionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSubstitutionRollup) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientSubstitutionRollupCodeLengthRule: LenientSubstitutionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient substitution rollup.
    final class LenientSubstitutionRollupValidator {
        var rules: [any LenientSubstitutionRollupRule]

        init(rules: [any LenientSubstitutionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSubstitutionRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSubstitutionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSubstitutionRollup]) -> [String: [String]] {
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

    static func defaultLenientSubstitutionRollupValidator() -> LenientSubstitutionRollupValidator {
        return LenientSubstitutionRollupValidator(
            rules: [
                LenientSubstitutionRollupCodePrefixRule(prefix: "X"),
                LenientSubstitutionRollupFloorValueRangeRule(min: 8.4, max: 4263.9),
                LenientSubstitutionRollupRequiredLabelRule(message: "lenient substitution rollup needs a value"),
                LenientSubstitutionRollupGraceDaysRangeRule(min: 32, max: 32),
                LenientSubstitutionRollupCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
