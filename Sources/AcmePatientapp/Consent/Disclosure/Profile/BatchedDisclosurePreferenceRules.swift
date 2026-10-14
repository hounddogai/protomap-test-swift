import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched disclosure preference must pass. Check returns its problems, or none.
    protocol BatchedDisclosurePreferenceRule {
        func check(_ item: BatchedDisclosurePreference) -> [String]
    }

    final class BatchedDisclosurePreferenceCodeLengthRule: BatchedDisclosurePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosurePreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosurePreferenceRequiredEncounterIDRule: BatchedDisclosurePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosurePreference) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosurePreferenceTimezoneLengthRule: BatchedDisclosurePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosurePreference) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched disclosure preference.
    final class BatchedDisclosurePreferenceValidator {
        var rules: [any BatchedDisclosurePreferenceRule]

        init(rules: [any BatchedDisclosurePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDisclosurePreference) -> [String] {
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

        func requireValid(_ item: BatchedDisclosurePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDisclosurePreference]) -> [String: [String]] {
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

    static func defaultBatchedDisclosurePreferenceValidator() -> BatchedDisclosurePreferenceValidator {
        return BatchedDisclosurePreferenceValidator(
            rules: [
                BatchedDisclosurePreferenceCodeLengthRule(maxLength: 1000),
                BatchedDisclosurePreferenceRequiredEncounterIDRule(
                    message: "batched disclosure preference needs a value"
                ),
                BatchedDisclosurePreferenceTimezoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
