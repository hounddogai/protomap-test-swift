import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach notice must pass. Check returns its problems, or none.
    protocol OutreachNoticeRule {
        func check(_ item: OutreachNotice) -> [String]
    }

    final class OutreachNoticeRetriesRangeRule: OutreachNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachNotice) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachNoticeCodeLengthRule: OutreachNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachNoticeUpdatedAtRangeRule: OutreachNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachNotice) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachNoticeRequiredLabelRule: OutreachNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachNoticeDiagnosisCodeLengthRule: OutreachNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachNotice) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachNoticeRateRangeRule: OutreachNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachNotice) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach notice.
    final class OutreachNoticeValidator {
        var rules: [any OutreachNoticeRule]

        init(rules: [any OutreachNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachNotice) -> [String] {
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

        func requireValid(_ item: OutreachNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachNotice]) -> [String: [String]] {
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

    static func defaultOutreachNoticeValidator() -> OutreachNoticeValidator {
        return OutreachNoticeValidator(
            rules: [
                OutreachNoticeRetriesRangeRule(min: 32, max: 86400),
                OutreachNoticeCodeLengthRule(maxLength: 64),
                OutreachNoticeUpdatedAtRangeRule(min: 80, max: 1000),
                OutreachNoticeRequiredLabelRule(message: "outreach notice needs a value"),
                OutreachNoticeDiagnosisCodeLengthRule(maxLength: 1000),
                OutreachNoticeRateRangeRule(min: 2.8, max: 4816.2),
            ]
        )
    }
}
