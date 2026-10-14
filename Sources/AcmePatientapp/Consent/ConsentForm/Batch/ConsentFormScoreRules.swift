import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form score must pass. Check returns its problems, or none.
    protocol ConsentFormScoreRule {
        func check(_ item: ConsentFormScore) -> [String]
    }

    final class ConsentFormScoreRatioRangeRule: ConsentFormScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormScore) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ConsentFormScoreCodePrefixRule: ConsentFormScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormScoreAllowedCodeRule: ConsentFormScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ConsentFormScoreAttemptsRangeRule: ConsentFormScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormScore) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a consent form score.
    final class ConsentFormScoreValidator {
        var rules: [any ConsentFormScoreRule]

        init(rules: [any ConsentFormScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormScore]) -> [String: [String]] {
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

    static func defaultConsentFormScoreValidator() -> ConsentFormScoreValidator {
        return ConsentFormScoreValidator(
            rules: [
                ConsentFormScoreRatioRangeRule(min: 2.7, max: 1927.4),
                ConsentFormScoreCodePrefixRule(prefix: "REF"),
                ConsentFormScoreAllowedCodeRule(allowed: ["pending", "regional"]),
                ConsentFormScoreAttemptsRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
