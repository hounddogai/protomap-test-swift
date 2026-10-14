import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling alert notice must pass. Check returns its problems, or none.
    protocol RollingAlertNoticeRule {
        func check(_ item: RollingAlertNotice) -> [String]
    }

    final class RollingAlertNoticeRequiredPayerRule: RollingAlertNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertNotice) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertNoticeRequiredSummaryRule: RollingAlertNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertNotice) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertNoticeRevisionRangeRule: RollingAlertNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAlertNotice) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling alert notice.
    final class RollingAlertNoticeValidator {
        var rules: [any RollingAlertNoticeRule]

        init(rules: [any RollingAlertNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAlertNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAlertNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAlertNotice]) -> [String: [String]] {
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

    static func defaultRollingAlertNoticeValidator() -> RollingAlertNoticeValidator {
        return RollingAlertNoticeValidator(
            rules: [
                RollingAlertNoticeRequiredPayerRule(message: "rolling alert notice needs this field"),
                RollingAlertNoticeRequiredSummaryRule(message: "rolling alert notice needs this field"),
                RollingAlertNoticeRevisionRangeRule(min: 80, max: 80),
            ]
        )
    }
}
