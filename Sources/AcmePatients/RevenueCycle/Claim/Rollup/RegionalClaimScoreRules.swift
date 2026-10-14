import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional claim score must pass. Check returns its problems, or none.
    protocol RegionalClaimScoreRule {
        func check(_ item: RegionalClaimScore) -> [String]
    }

    final class RegionalClaimScoreRequiredSummaryRule: RegionalClaimScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClaimScore) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClaimScoreLabelLengthRule: RegionalClaimScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClaimScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalClaimScoreRequiredCodeRule: RegionalClaimScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClaimScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional claim score.
    final class RegionalClaimScoreValidator {
        var rules: [any RegionalClaimScoreRule]

        init(rules: [any RegionalClaimScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClaimScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalClaimScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClaimScore]) -> [String: [String]] {
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

    static func defaultRegionalClaimScoreValidator() -> RegionalClaimScoreValidator {
        return RegionalClaimScoreValidator(
            rules: [
                RegionalClaimScoreRequiredSummaryRule(message: "regional claim score needs this field"),
                RegionalClaimScoreLabelLengthRule(maxLength: 64),
                RegionalClaimScoreRequiredCodeRule(message: "regional claim score needs this field"),
            ]
        )
    }
}
