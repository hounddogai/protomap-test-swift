import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional assessment score must pass. Check returns its problems, or none.
    protocol RegionalAssessmentScoreRule {
        func check(_ item: RegionalAssessmentScore) -> [String]
    }

    final class RegionalAssessmentScoreRequiredCodeRule: RegionalAssessmentScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAssessmentScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAssessmentScoreCodePrefixRule: RegionalAssessmentScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalAssessmentScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalAssessmentScoreVersionRangeRule: RegionalAssessmentScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAssessmentScore) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAssessmentScoreAllowedCountryRule: RegionalAssessmentScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalAssessmentScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is stale"]
            }
            return []
        }
    }

    final class RegionalAssessmentScoreRequiredSegmentRule: RegionalAssessmentScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAssessmentScore) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAssessmentScoreRequiredTitleRule: RegionalAssessmentScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAssessmentScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional assessment score.
    final class RegionalAssessmentScoreValidator {
        var rules: [any RegionalAssessmentScoreRule]

        init(rules: [any RegionalAssessmentScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAssessmentScore) -> [String] {
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

        func requireValid(_ item: RegionalAssessmentScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAssessmentScore]) -> [String: [String]] {
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

    static func defaultRegionalAssessmentScoreValidator() -> RegionalAssessmentScoreValidator {
        return RegionalAssessmentScoreValidator(
            rules: [
                RegionalAssessmentScoreRequiredCodeRule(message: "regional assessment score needs a value"),
                RegionalAssessmentScoreCodePrefixRule(prefix: "X"),
                RegionalAssessmentScoreVersionRangeRule(min: 1000, max: 1000),
                RegionalAssessmentScoreAllowedCountryRule(allowed: ["rolling", "manual", "manual"]),
                RegionalAssessmentScoreRequiredSegmentRule(message: "regional assessment score needs a value"),
                RegionalAssessmentScoreRequiredTitleRule(message: "regional assessment score needs a value"),
            ]
        )
    }
}
