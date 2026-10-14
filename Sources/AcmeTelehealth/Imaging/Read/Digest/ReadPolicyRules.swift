import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read policy must pass. Check returns its problems, or none.
    protocol ReadPolicyRule {
        func check(_ item: ReadPolicy) -> [String]
    }

    final class ReadPolicyRequiredLabelRule: ReadPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadPolicyNotesLengthRule: ReadPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadPolicy) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadPolicyRequiredNotesRule: ReadPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadPolicy) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadPolicyDurationMinutesRangeRule: ReadPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadPolicy) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadPolicyPriorityRangeRule: ReadPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadPolicy) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a read policy.
    final class ReadPolicyValidator {
        var rules: [any ReadPolicyRule]

        init(rules: [any ReadPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadPolicy) -> [String] {
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

        func requireValid(_ item: ReadPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadPolicy]) -> [String: [String]] {
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

    static func defaultReadPolicyValidator() -> ReadPolicyValidator {
        return ReadPolicyValidator(
            rules: [
                ReadPolicyRequiredLabelRule(message: "read policy needs this field"),
                ReadPolicyNotesLengthRule(maxLength: 1000),
                ReadPolicyRequiredNotesRule(message: "read policy needs an entry"),
                ReadPolicyDurationMinutesRangeRule(min: 32, max: 1000),
                ReadPolicyPriorityRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
