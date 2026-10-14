import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall notice must pass. Check returns its problems, or none.
    protocol ManualRecallNoticeRule {
        func check(_ item: ManualRecallNotice) -> [String]
    }

    final class ManualRecallNoticeVersionRangeRule: ManualRecallNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallNotice) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRecallNoticeRequiredLabelRule: ManualRecallNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallNoticeBedLengthRule: ManualRecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallNotice) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallNoticeCodeLengthRule: ManualRecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallNoticeRequiredBedRule: ManualRecallNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallNotice) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallNoticeLocaleLengthRule: ManualRecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallNotice) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual recall notice.
    final class ManualRecallNoticeValidator {
        var rules: [any ManualRecallNoticeRule]

        init(rules: [any ManualRecallNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallNotice) -> [String] {
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

        func requireValid(_ item: ManualRecallNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallNotice]) -> [String: [String]] {
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

    static func defaultManualRecallNoticeValidator() -> ManualRecallNoticeValidator {
        return ManualRecallNoticeValidator(
            rules: [
                ManualRecallNoticeVersionRangeRule(min: 32, max: 32),
                ManualRecallNoticeRequiredLabelRule(message: "manual recall notice needs an entry"),
                ManualRecallNoticeBedLengthRule(maxLength: 3600),
                ManualRecallNoticeCodeLengthRule(maxLength: 120),
                ManualRecallNoticeRequiredBedRule(message: "manual recall notice needs a value"),
                ManualRecallNoticeLocaleLengthRule(maxLength: 255),
            ]
        )
    }
}
