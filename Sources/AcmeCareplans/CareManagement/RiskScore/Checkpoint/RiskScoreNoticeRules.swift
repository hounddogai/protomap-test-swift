import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score notice must pass. Check returns its problems, or none.
    protocol RiskScoreNoticeRule {
        func check(_ item: RiskScoreNotice) -> [String]
    }

    final class RiskScoreNoticeThresholdRangeRule: RiskScoreNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreNotice) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreNoticeRequiredProcedureCodeRule: RiskScoreNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreNotice) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreNoticeAllowedCodeRule: RiskScoreNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class RiskScoreNoticeNameLengthRule: RiskScoreNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score notice.
    final class RiskScoreNoticeValidator {
        var rules: [any RiskScoreNoticeRule]

        init(rules: [any RiskScoreNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreNotice) -> [String] {
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

        func requireValid(_ item: RiskScoreNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreNotice]) -> [String: [String]] {
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

    static func defaultRiskScoreNoticeValidator() -> RiskScoreNoticeValidator {
        return RiskScoreNoticeValidator(
            rules: [
                RiskScoreNoticeThresholdRangeRule(min: 3.7, max: 1137.8),
                RiskScoreNoticeRequiredProcedureCodeRule(message: "risk score notice needs a value"),
                RiskScoreNoticeAllowedCodeRule(allowed: ["weighted"]),
                RiskScoreNoticeNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
