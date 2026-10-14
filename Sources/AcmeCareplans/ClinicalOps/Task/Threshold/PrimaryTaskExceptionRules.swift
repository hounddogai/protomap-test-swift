import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary task exception must pass. Check returns its problems, or none.
    protocol PrimaryTaskExceptionRule {
        func check(_ item: PrimaryTaskException) -> [String]
    }

    final class PrimaryTaskExceptionSequenceRangeRule: PrimaryTaskExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryTaskException) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryTaskExceptionRequiredCodeRule: PrimaryTaskExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTaskException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTaskExceptionCodeLengthRule: PrimaryTaskExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTaskExceptionActiveGuardRule: PrimaryTaskExceptionRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryTaskException) -> [String] {
            if item.active && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PrimaryTaskExceptionLabelLengthRule: PrimaryTaskExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary task exception.
    final class PrimaryTaskExceptionValidator {
        var rules: [any PrimaryTaskExceptionRule]

        init(rules: [any PrimaryTaskExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTaskException) -> [String] {
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

        func requireValid(_ item: PrimaryTaskException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTaskException]) -> [String: [String]] {
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

    static func defaultPrimaryTaskExceptionValidator() -> PrimaryTaskExceptionValidator {
        return PrimaryTaskExceptionValidator(
            rules: [
                PrimaryTaskExceptionSequenceRangeRule(min: 32, max: 86400),
                PrimaryTaskExceptionRequiredCodeRule(message: "primary task exception needs this field"),
                PrimaryTaskExceptionCodeLengthRule(maxLength: 86400),
                PrimaryTaskExceptionActiveGuardRule(limit: 2.5),
                PrimaryTaskExceptionLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
