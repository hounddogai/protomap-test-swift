import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped risk score notice must pass. Check returns its problems, or none.
    protocol CappedRiskScoreNoticeRule {
        func check(_ item: CappedRiskScoreNotice) -> [String]
    }

    final class CappedRiskScoreNoticePriorityRangeRule: CappedRiskScoreNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRiskScoreNotice) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedRiskScoreNoticeRequiredWardRule: CappedRiskScoreNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRiskScoreNotice) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRiskScoreNoticeRefillsRangeRule: CappedRiskScoreNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRiskScoreNotice) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedRiskScoreNoticeCodePrefixRule: CappedRiskScoreNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRiskScoreNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped risk score notice.
    final class CappedRiskScoreNoticeValidator {
        var rules: [any CappedRiskScoreNoticeRule]

        init(rules: [any CappedRiskScoreNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRiskScoreNotice) -> [String] {
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

        func requireValid(_ item: CappedRiskScoreNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRiskScoreNotice]) -> [String: [String]] {
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

    static func defaultCappedRiskScoreNoticeValidator() -> CappedRiskScoreNoticeValidator {
        return CappedRiskScoreNoticeValidator(
            rules: [
                CappedRiskScoreNoticePriorityRangeRule(min: 80, max: 80),
                CappedRiskScoreNoticeRequiredWardRule(message: "capped risk score notice needs this field"),
                CappedRiskScoreNoticeRefillsRangeRule(min: 120, max: 86400),
                CappedRiskScoreNoticeCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
