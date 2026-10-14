import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global substitution score must pass. Check returns its problems, or none.
    protocol GlobalSubstitutionScoreRule {
        func check(_ item: GlobalSubstitutionScore) -> [String]
    }

    final class GlobalSubstitutionScoreScoreRangeRule: GlobalSubstitutionScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSubstitutionScore) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSubstitutionScoreCodePrefixRule: GlobalSubstitutionScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalSubstitutionScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalSubstitutionScoreCodeLengthRule: GlobalSubstitutionScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSubstitutionScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global substitution score.
    final class GlobalSubstitutionScoreValidator {
        var rules: [any GlobalSubstitutionScoreRule]

        init(rules: [any GlobalSubstitutionScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSubstitutionScore) -> [String] {
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

        func requireValid(_ item: GlobalSubstitutionScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSubstitutionScore]) -> [String: [String]] {
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

    static func defaultGlobalSubstitutionScoreValidator() -> GlobalSubstitutionScoreValidator {
        return GlobalSubstitutionScoreValidator(
            rules: [
                GlobalSubstitutionScoreScoreRangeRule(min: 3.5, max: 2856.4),
                GlobalSubstitutionScoreCodePrefixRule(prefix: "X"),
                GlobalSubstitutionScoreCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
