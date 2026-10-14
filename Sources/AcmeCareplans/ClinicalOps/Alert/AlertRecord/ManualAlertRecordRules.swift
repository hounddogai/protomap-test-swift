import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual alert record must pass. Check returns its problems, or none.
    protocol ManualAlertRecordRule {
        func check(_ item: ManualAlertRecord) -> [String]
    }

    final class ManualAlertRecordAllowedCodeRule: ManualAlertRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAlertRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ManualAlertRecordRequiredCodeRule: ManualAlertRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAlertRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAlertRecordContactEmailLengthRule: ManualAlertRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAlertRecord) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAlertRecordBatchSizeRangeRule: ManualAlertRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAlertRecord) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualAlertRecordTitleLengthRule: ManualAlertRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAlertRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAlertRecordRequiredTitleRule: ManualAlertRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAlertRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual alert record.
    final class ManualAlertRecordValidator {
        var rules: [any ManualAlertRecordRule]

        init(rules: [any ManualAlertRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAlertRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAlertRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAlertRecord]) -> [String: [String]] {
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

    static func defaultManualAlertRecordValidator() -> ManualAlertRecordValidator {
        return ManualAlertRecordValidator(
            rules: [
                ManualAlertRecordAllowedCodeRule(allowed: ["lenient", "tiered"]),
                ManualAlertRecordRequiredCodeRule(message: "manual alert record needs this field"),
                ManualAlertRecordContactEmailLengthRule(maxLength: 16),
                ManualAlertRecordBatchSizeRangeRule(min: 32, max: 1000),
                ManualAlertRecordTitleLengthRule(maxLength: 80),
                ManualAlertRecordRequiredTitleRule(message: "manual alert record needs this field"),
            ]
        )
    }
}
