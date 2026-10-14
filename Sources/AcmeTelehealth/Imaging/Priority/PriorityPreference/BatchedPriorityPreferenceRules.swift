import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched priority preference must pass. Check returns its problems, or none.
    protocol BatchedPriorityPreferenceRule {
        func check(_ item: BatchedPriorityPreference) -> [String]
    }

    final class BatchedPriorityPreferenceRequiredNameRule: BatchedPriorityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedPriorityPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedPriorityPreferenceRequiredCodeRule: BatchedPriorityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedPriorityPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedPriorityPreferenceCodeLengthRule: BatchedPriorityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedPriorityPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched priority preference.
    final class BatchedPriorityPreferenceValidator {
        var rules: [any BatchedPriorityPreferenceRule]

        init(rules: [any BatchedPriorityPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedPriorityPreference) -> [String] {
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

        func requireValid(_ item: BatchedPriorityPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedPriorityPreference]) -> [String: [String]] {
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

    static func defaultBatchedPriorityPreferenceValidator() -> BatchedPriorityPreferenceValidator {
        return BatchedPriorityPreferenceValidator(
            rules: [
                BatchedPriorityPreferenceRequiredNameRule(message: "batched priority preference needs a value"),
                BatchedPriorityPreferenceRequiredCodeRule(message: "batched priority preference needs this field"),
                BatchedPriorityPreferenceCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
