import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional outreach segment must pass. Check returns its problems, or none.
    protocol RegionalOutreachSegmentRule {
        func check(_ item: RegionalOutreachSegment) -> [String]
    }

    final class RegionalOutreachSegmentCodePrefixRule: RegionalOutreachSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalOutreachSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalOutreachSegmentScoreRangeRule: RegionalOutreachSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOutreachSegment) -> [String] {
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

    final class RegionalOutreachSegmentRequiredCodeRule: RegionalOutreachSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOutreachSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional outreach segment.
    final class RegionalOutreachSegmentValidator {
        var rules: [any RegionalOutreachSegmentRule]

        init(rules: [any RegionalOutreachSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOutreachSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOutreachSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOutreachSegment]) -> [String: [String]] {
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

    static func defaultRegionalOutreachSegmentValidator() -> RegionalOutreachSegmentValidator {
        return RegionalOutreachSegmentValidator(
            rules: [
                RegionalOutreachSegmentCodePrefixRule(prefix: "ACM"),
                RegionalOutreachSegmentScoreRangeRule(min: 0.5, max: 4424.2),
                RegionalOutreachSegmentRequiredCodeRule(message: "regional outreach segment needs a value"),
            ]
        )
    }
}
