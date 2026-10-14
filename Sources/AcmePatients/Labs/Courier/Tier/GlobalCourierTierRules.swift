import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global courier tier must pass. Check returns its problems, or none.
    protocol GlobalCourierTierRule {
        func check(_ item: GlobalCourierTier) -> [String]
    }

    final class GlobalCourierTierWeightRangeRule: GlobalCourierTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCourierTier) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCourierTierCodePrefixRule: GlobalCourierTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCourierTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCourierTierScoreRangeRule: GlobalCourierTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCourierTier) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalCourierTierRequiredNotesRule: GlobalCourierTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCourierTier) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global courier tier.
    final class GlobalCourierTierValidator {
        var rules: [any GlobalCourierTierRule]

        init(rules: [any GlobalCourierTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCourierTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCourierTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCourierTier]) -> [String: [String]] {
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

    static func defaultGlobalCourierTierValidator() -> GlobalCourierTierValidator {
        return GlobalCourierTierValidator(
            rules: [
                GlobalCourierTierWeightRangeRule(min: 5.1, max: 327.7),
                GlobalCourierTierCodePrefixRule(prefix: "X"),
                GlobalCourierTierScoreRangeRule(min: 9.1, max: 4967.3),
                GlobalCourierTierRequiredNotesRule(message: "global courier tier needs a value"),
            ]
        )
    }
}
