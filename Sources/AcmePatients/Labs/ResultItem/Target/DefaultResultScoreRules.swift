import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default result score must pass. Check returns its problems, or none.
    protocol DefaultResultScoreRule {
        func check(_ item: DefaultResultScore) -> [String]
    }

    final class DefaultResultScoreRequiredNameRule: DefaultResultScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultResultScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultResultScoreRequiredSummaryRule: DefaultResultScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultResultScore) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultResultScoreSummaryLengthRule: DefaultResultScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultResultScore) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultResultScoreCountryLengthRule: DefaultResultScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultResultScore) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultResultScoreAllowedCodeRule: DefaultResultScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultResultScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class DefaultResultScoreAcuityRangeRule: DefaultResultScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultResultScore) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default result score.
    final class DefaultResultScoreValidator {
        var rules: [any DefaultResultScoreRule]

        init(rules: [any DefaultResultScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultResultScore) -> [String] {
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

        func requireValid(_ item: DefaultResultScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultResultScore]) -> [String: [String]] {
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

    static func defaultDefaultResultScoreValidator() -> DefaultResultScoreValidator {
        return DefaultResultScoreValidator(
            rules: [
                DefaultResultScoreRequiredNameRule(message: "default result score needs an entry"),
                DefaultResultScoreRequiredSummaryRule(message: "default result score needs an entry"),
                DefaultResultScoreSummaryLengthRule(maxLength: 86400),
                DefaultResultScoreCountryLengthRule(maxLength: 64),
                DefaultResultScoreAllowedCodeRule(allowed: []),
                DefaultResultScoreAcuityRangeRule(min: 120, max: 120),
            ]
        )
    }
}
