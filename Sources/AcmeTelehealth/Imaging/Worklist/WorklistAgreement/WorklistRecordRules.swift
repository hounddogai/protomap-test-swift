import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist record must pass. Check returns its problems, or none.
    protocol WorklistRecordRule {
        func check(_ item: WorklistRecord) -> [String]
    }

    final class WorklistRecordDescriptionLengthRule: WorklistRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistRecord) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistRecordRequiredDescriptionRule: WorklistRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistRecord) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistRecordRequiredContactEmailRule: WorklistRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistRecord) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistRecordCodePrefixRule: WorklistRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist record.
    final class WorklistRecordValidator {
        var rules: [any WorklistRecordRule]

        init(rules: [any WorklistRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistRecord) -> [String] {
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

        func requireValid(_ item: WorklistRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistRecord]) -> [String: [String]] {
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

    static func defaultWorklistRecordValidator() -> WorklistRecordValidator {
        return WorklistRecordValidator(
            rules: [
                WorklistRecordDescriptionLengthRule(maxLength: 64),
                WorklistRecordRequiredDescriptionRule(message: "worklist record needs this field"),
                WorklistRecordRequiredContactEmailRule(message: "worklist record needs this field"),
                WorklistRecordCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
