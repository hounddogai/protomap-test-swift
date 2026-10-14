import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict risk score notice must pass. Check returns its problems, or none.
    protocol StrictRiskScoreNoticeRule {
        func check(_ item: StrictRiskScoreNotice) -> [String]
    }

    final class StrictRiskScoreNoticeAllowedNameRule: StrictRiskScoreNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictRiskScoreNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class StrictRiskScoreNoticeGraceDaysRangeRule: StrictRiskScoreNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRiskScoreNotice) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictRiskScoreNoticeCodeLengthRule: StrictRiskScoreNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRiskScoreNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict risk score notice.
    final class StrictRiskScoreNoticeValidator {
        var rules: [any StrictRiskScoreNoticeRule]

        init(rules: [any StrictRiskScoreNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRiskScoreNotice) -> [String] {
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

        func requireValid(_ item: StrictRiskScoreNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRiskScoreNotice]) -> [String: [String]] {
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

    static func defaultStrictRiskScoreNoticeValidator() -> StrictRiskScoreNoticeValidator {
        return StrictRiskScoreNoticeValidator(
            rules: [
                StrictRiskScoreNoticeAllowedNameRule(allowed: ["manual", "strict", "legacy"]),
                StrictRiskScoreNoticeGraceDaysRangeRule(min: 64, max: 3600),
                StrictRiskScoreNoticeCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
