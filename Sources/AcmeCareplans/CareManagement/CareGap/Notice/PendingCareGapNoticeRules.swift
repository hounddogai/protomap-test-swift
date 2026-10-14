import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending care gap notice must pass. Check returns its problems, or none.
    protocol PendingCareGapNoticeRule {
        func check(_ item: PendingCareGapNotice) -> [String]
    }

    final class PendingCareGapNoticeRequiredLabelRule: PendingCareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareGapNoticeLabelLengthRule: PendingCareGapNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapNoticeRetriesRangeRule: PendingCareGapNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareGapNotice) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCareGapNoticeRequiredTimezoneRule: PendingCareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapNotice) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending care gap notice.
    final class PendingCareGapNoticeValidator {
        var rules: [any PendingCareGapNoticeRule]

        init(rules: [any PendingCareGapNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareGapNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCareGapNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareGapNotice]) -> [String: [String]] {
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

    static func defaultPendingCareGapNoticeValidator() -> PendingCareGapNoticeValidator {
        return PendingCareGapNoticeValidator(
            rules: [
                PendingCareGapNoticeRequiredLabelRule(message: "pending care gap notice needs a value"),
                PendingCareGapNoticeLabelLengthRule(maxLength: 86400),
                PendingCareGapNoticeRetriesRangeRule(min: 255, max: 86400),
                PendingCareGapNoticeRequiredTimezoneRule(message: "pending care gap notice needs this field"),
            ]
        )
    }
}
