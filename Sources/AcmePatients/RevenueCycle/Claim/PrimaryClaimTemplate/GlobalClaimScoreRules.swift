import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global claim score must pass. Check returns its problems, or none.
    protocol GlobalClaimScoreRule {
        func check(_ item: GlobalClaimScore) -> [String]
    }

    final class GlobalClaimScoreCodePrefixRule: GlobalClaimScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalClaimScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalClaimScoreCodeLengthRule: GlobalClaimScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalClaimScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalClaimScoreRequiredAllergyRule: GlobalClaimScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalClaimScore) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalClaimScoreRetriesRangeRule: GlobalClaimScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalClaimScore) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalClaimScoreSummaryLengthRule: GlobalClaimScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalClaimScore) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global claim score.
    final class GlobalClaimScoreValidator {
        var rules: [any GlobalClaimScoreRule]

        init(rules: [any GlobalClaimScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalClaimScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalClaimScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalClaimScore]) -> [String: [String]] {
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

    static func defaultGlobalClaimScoreValidator() -> GlobalClaimScoreValidator {
        return GlobalClaimScoreValidator(
            rules: [
                GlobalClaimScoreCodePrefixRule(prefix: "OPS"),
                GlobalClaimScoreCodeLengthRule(maxLength: 32),
                GlobalClaimScoreRequiredAllergyRule(message: "global claim score needs an entry"),
                GlobalClaimScoreRetriesRangeRule(min: 80, max: 1000),
                GlobalClaimScoreSummaryLengthRule(maxLength: 3600),
            ]
        )
    }
}
