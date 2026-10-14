import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim score must pass. Check returns its problems, or none.
    protocol ClaimScoreRule {
        func check(_ item: ClaimScore) -> [String]
    }

    final class ClaimScoreCodeLengthRule: ClaimScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimScoreScoreRangeRule: ClaimScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimScore) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimScoreTitleLengthRule: ClaimScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim score.
    final class ClaimScoreValidator {
        var rules: [any ClaimScoreRule]

        init(rules: [any ClaimScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimScore]) -> [String: [String]] {
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

    static func defaultClaimScoreValidator() -> ClaimScoreValidator {
        return ClaimScoreValidator(
            rules: [
                ClaimScoreCodeLengthRule(maxLength: 1000),
                ClaimScoreScoreRangeRule(min: 0.8, max: 1009.4),
                ClaimScoreTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
