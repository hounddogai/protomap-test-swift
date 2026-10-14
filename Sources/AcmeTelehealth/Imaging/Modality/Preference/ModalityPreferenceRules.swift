import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality preference must pass. Check returns its problems, or none.
    protocol ModalityPreferenceRule {
        func check(_ item: ModalityPreference) -> [String]
    }

    final class ModalityPreferenceAllowedSummaryRule: ModalityPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is blocked"]
            }
            return []
        }
    }

    final class ModalityPreferenceOwnerIDLengthRule: ModalityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityPreference) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityPreferenceAttemptsRangeRule: ModalityPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityPreference) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityPreferenceRequiredTitleRule: ModalityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityPreferenceRequiredCodeRule: ModalityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality preference.
    final class ModalityPreferenceValidator {
        var rules: [any ModalityPreferenceRule]

        init(rules: [any ModalityPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityPreference) -> [String] {
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

        func requireValid(_ item: ModalityPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityPreference]) -> [String: [String]] {
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

    static func defaultModalityPreferenceValidator() -> ModalityPreferenceValidator {
        return ModalityPreferenceValidator(
            rules: [
                ModalityPreferenceAllowedSummaryRule(allowed: []),
                ModalityPreferenceOwnerIDLengthRule(maxLength: 32),
                ModalityPreferenceAttemptsRangeRule(min: 16, max: 32),
                ModalityPreferenceRequiredTitleRule(message: "modality preference needs a value"),
                ModalityPreferenceRequiredCodeRule(message: "modality preference needs this field"),
            ]
        )
    }
}
