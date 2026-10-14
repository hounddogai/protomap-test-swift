import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist notice must pass. Check returns its problems, or none.
    protocol WorklistNoticeRule {
        func check(_ item: WorklistNotice) -> [String]
    }

    final class WorklistNoticeRetriesRangeRule: WorklistNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistNotice) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistNoticeNameLengthRule: WorklistNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistNoticeAcuityRangeRule: WorklistNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistNotice) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistNoticeCodeLengthRule: WorklistNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistNoticeRequiredCodeRule: WorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistNoticeRequiredSegmentRule: WorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistNotice) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist notice.
    final class WorklistNoticeValidator {
        var rules: [any WorklistNoticeRule]

        init(rules: [any WorklistNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistNotice]) -> [String: [String]] {
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

    static func defaultWorklistNoticeValidator() -> WorklistNoticeValidator {
        return WorklistNoticeValidator(
            rules: [
                WorklistNoticeRetriesRangeRule(min: 16, max: 32),
                WorklistNoticeNameLengthRule(maxLength: 16),
                WorklistNoticeAcuityRangeRule(min: 32, max: 255),
                WorklistNoticeCodeLengthRule(maxLength: 120),
                WorklistNoticeRequiredCodeRule(message: "worklist notice needs this field"),
                WorklistNoticeRequiredSegmentRule(message: "worklist notice needs a value"),
            ]
        )
    }
}
