import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score audit must pass. Check returns its problems, or none.
    protocol RiskScoreAuditRule {
        func check(_ item: RiskScoreAudit) -> [String]
    }

    final class RiskScoreAuditCodePrefixRule: RiskScoreAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreAuditTitleLengthRule: RiskScoreAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreAuditWindowDaysRangeRule: RiskScoreAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreAudit) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a risk score audit.
    final class RiskScoreAuditValidator {
        var rules: [any RiskScoreAuditRule]

        init(rules: [any RiskScoreAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreAudit]) -> [String: [String]] {
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

    static func defaultRiskScoreAuditValidator() -> RiskScoreAuditValidator {
        return RiskScoreAuditValidator(
            rules: [
                RiskScoreAuditCodePrefixRule(prefix: "REF"),
                RiskScoreAuditTitleLengthRule(maxLength: 120),
                RiskScoreAuditWindowDaysRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
