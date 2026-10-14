import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive follow up baseline must pass. Check returns its problems, or none.
    protocol AdaptiveFollowUpBaselineRule {
        func check(_ item: AdaptiveFollowUpBaseline) -> [String]
    }

    final class AdaptiveFollowUpBaselineRequiredTitleRule: AdaptiveFollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFollowUpBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFollowUpBaselineCodeLengthRule: AdaptiveFollowUpBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFollowUpBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFollowUpBaselineSequenceRangeRule: AdaptiveFollowUpBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpBaseline) -> [String] {
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

    final class AdaptiveFollowUpBaselineScoreRangeRule: AdaptiveFollowUpBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpBaseline) -> [String] {
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

    final class AdaptiveFollowUpBaselineCodePrefixRule: AdaptiveFollowUpBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveFollowUpBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive follow up baseline.
    final class AdaptiveFollowUpBaselineValidator {
        var rules: [any AdaptiveFollowUpBaselineRule]

        init(rules: [any AdaptiveFollowUpBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFollowUpBaseline) -> [String] {
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

        func requireValid(_ item: AdaptiveFollowUpBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFollowUpBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveFollowUpBaselineValidator() -> AdaptiveFollowUpBaselineValidator {
        return AdaptiveFollowUpBaselineValidator(
            rules: [
                AdaptiveFollowUpBaselineRequiredTitleRule(message: "adaptive follow up baseline needs a value"),
                AdaptiveFollowUpBaselineCodeLengthRule(maxLength: 255),
                AdaptiveFollowUpBaselineSequenceRangeRule(min: 16, max: 1000),
                AdaptiveFollowUpBaselineScoreRangeRule(min: 0.7, max: 1111.3),
                AdaptiveFollowUpBaselineCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
