import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert draft must pass. Check returns its problems, or none.
    protocol AlertDraftRule {
        func check(_ item: AlertDraft) -> [String]
    }

    final class AlertDraftWeightRangeRule: AlertDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertDraft) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertDraftCodePrefixRule: AlertDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertDraftRequiredTitleRule: AlertDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertDraftTitleLengthRule: AlertDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertDraftRequiredBedRule: AlertDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertDraft) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertDraftAttemptsRangeRule: AlertDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertDraft) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert draft.
    final class AlertDraftValidator {
        var rules: [any AlertDraftRule]

        init(rules: [any AlertDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertDraft) -> [String] {
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

        func requireValid(_ item: AlertDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertDraft]) -> [String: [String]] {
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

    static func defaultAlertDraftValidator() -> AlertDraftValidator {
        return AlertDraftValidator(
            rules: [
                AlertDraftWeightRangeRule(min: 9.8, max: 4268.7),
                AlertDraftCodePrefixRule(prefix: "Q"),
                AlertDraftRequiredTitleRule(message: "alert draft needs an entry"),
                AlertDraftTitleLengthRule(maxLength: 255),
                AlertDraftRequiredBedRule(message: "alert draft needs an entry"),
                AlertDraftAttemptsRangeRule(min: 32, max: 120),
            ]
        )
    }
}
