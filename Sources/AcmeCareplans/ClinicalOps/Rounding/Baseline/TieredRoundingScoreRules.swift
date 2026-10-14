import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered rounding score must pass. Check returns its problems, or none.
    protocol TieredRoundingScoreRule {
        func check(_ item: TieredRoundingScore) -> [String]
    }

    final class TieredRoundingScoreRequiredCodeRule: TieredRoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRoundingScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRoundingScoreRequiredBedRule: TieredRoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRoundingScore) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRoundingScoreBedLengthRule: TieredRoundingScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRoundingScore) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered rounding score.
    final class TieredRoundingScoreValidator {
        var rules: [any TieredRoundingScoreRule]

        init(rules: [any TieredRoundingScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRoundingScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRoundingScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRoundingScore]) -> [String: [String]] {
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

    static func defaultTieredRoundingScoreValidator() -> TieredRoundingScoreValidator {
        return TieredRoundingScoreValidator(
            rules: [
                TieredRoundingScoreRequiredCodeRule(message: "tiered rounding score needs an entry"),
                TieredRoundingScoreRequiredBedRule(message: "tiered rounding score needs an entry"),
                TieredRoundingScoreBedLengthRule(maxLength: 86400),
            ]
        )
    }
}
