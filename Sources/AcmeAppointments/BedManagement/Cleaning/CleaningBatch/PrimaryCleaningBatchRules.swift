import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary cleaning batch must pass. Check returns its problems, or none.
    protocol PrimaryCleaningBatchRule {
        func check(_ item: PrimaryCleaningBatch) -> [String]
    }

    final class PrimaryCleaningBatchRequiredCodeRule: PrimaryCleaningBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCleaningBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCleaningBatchLabelLengthRule: PrimaryCleaningBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCleaningBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCleaningBatchExpiresAtRangeRule: PrimaryCleaningBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCleaningBatch) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary cleaning batch.
    final class PrimaryCleaningBatchValidator {
        var rules: [any PrimaryCleaningBatchRule]

        init(rules: [any PrimaryCleaningBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCleaningBatch) -> [String] {
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

        func requireValid(_ item: PrimaryCleaningBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCleaningBatch]) -> [String: [String]] {
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

    static func defaultPrimaryCleaningBatchValidator() -> PrimaryCleaningBatchValidator {
        return PrimaryCleaningBatchValidator(
            rules: [
                PrimaryCleaningBatchRequiredCodeRule(message: "primary cleaning batch needs a value"),
                PrimaryCleaningBatchLabelLengthRule(maxLength: 86400),
                PrimaryCleaningBatchExpiresAtRangeRule(min: 16, max: 16),
            ]
        )
    }
}
