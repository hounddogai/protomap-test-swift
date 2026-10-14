import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary proxy score must pass. Check returns its problems, or none.
    protocol PrimaryProxyScoreRule {
        func check(_ item: PrimaryProxyScore) -> [String]
    }

    final class PrimaryProxyScoreLocaleLengthRule: PrimaryProxyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryProxyScore) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryProxyScoreSequenceRangeRule: PrimaryProxyScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryProxyScore) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryProxyScoreLimitRangeRule: PrimaryProxyScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryProxyScore) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary proxy score.
    final class PrimaryProxyScoreValidator {
        var rules: [any PrimaryProxyScoreRule]

        init(rules: [any PrimaryProxyScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryProxyScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryProxyScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryProxyScore]) -> [String: [String]] {
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

    static func defaultPrimaryProxyScoreValidator() -> PrimaryProxyScoreValidator {
        return PrimaryProxyScoreValidator(
            rules: [
                PrimaryProxyScoreLocaleLengthRule(maxLength: 86400),
                PrimaryProxyScoreSequenceRangeRule(min: 80, max: 120),
                PrimaryProxyScoreLimitRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
