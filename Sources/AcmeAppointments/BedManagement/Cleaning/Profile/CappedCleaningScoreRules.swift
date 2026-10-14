import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped cleaning score must pass. Check returns its problems, or none.
    protocol CappedCleaningScoreRule {
        func check(_ item: CappedCleaningScore) -> [String]
    }

    final class CappedCleaningScoreAllowedCodeRule: CappedCleaningScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCleaningScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CappedCleaningScoreCostRangeRule: CappedCleaningScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCleaningScore) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCleaningScoreCodeLengthRule: CappedCleaningScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCleaningScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCleaningScoreRateRangeRule: CappedCleaningScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCleaningScore) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCleaningScoreCodePrefixRule: CappedCleaningScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCleaningScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped cleaning score.
    final class CappedCleaningScoreValidator {
        var rules: [any CappedCleaningScoreRule]

        init(rules: [any CappedCleaningScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCleaningScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCleaningScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCleaningScore]) -> [String: [String]] {
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

    static func defaultCappedCleaningScoreValidator() -> CappedCleaningScoreValidator {
        return CappedCleaningScoreValidator(
            rules: [
                CappedCleaningScoreAllowedCodeRule(allowed: []),
                CappedCleaningScoreCostRangeRule(min: 8.9, max: 3383.8),
                CappedCleaningScoreCodeLengthRule(maxLength: 255),
                CappedCleaningScoreRateRangeRule(min: 1.9, max: 4851.7),
                CappedCleaningScoreCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
