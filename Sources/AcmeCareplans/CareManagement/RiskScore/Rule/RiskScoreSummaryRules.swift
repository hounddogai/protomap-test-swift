import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score summary must pass. Check returns its problems, or none.
    protocol RiskScoreSummaryRule {
        func check(_ item: RiskScoreSummary) -> [String]
    }

    final class RiskScoreSummaryAllowedTitleRule: RiskScoreSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class RiskScoreSummaryVisitMinutesRangeRule: RiskScoreSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreSummary) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreSummaryTitleLengthRule: RiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreSummaryCodeLengthRule: RiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score summary.
    final class RiskScoreSummaryValidator {
        var rules: [any RiskScoreSummaryRule]

        init(rules: [any RiskScoreSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreSummary) -> [String] {
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

        func requireValid(_ item: RiskScoreSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreSummary]) -> [String: [String]] {
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

    static func defaultRiskScoreSummaryValidator() -> RiskScoreSummaryValidator {
        return RiskScoreSummaryValidator(
            rules: [
                RiskScoreSummaryAllowedTitleRule(allowed: ["lenient"]),
                RiskScoreSummaryVisitMinutesRangeRule(min: 32, max: 64),
                RiskScoreSummaryTitleLengthRule(maxLength: 120),
                RiskScoreSummaryCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
