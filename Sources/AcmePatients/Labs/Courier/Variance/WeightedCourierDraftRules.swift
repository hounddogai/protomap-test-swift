import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted courier draft must pass. Check returns its problems, or none.
    protocol WeightedCourierDraftRule {
        func check(_ item: WeightedCourierDraft) -> [String]
    }

    final class WeightedCourierDraftCodeLengthRule: WeightedCourierDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCourierDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCourierDraftRequiredTitleRule: WeightedCourierDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCourierDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCourierDraftAllowedTitleRule: WeightedCourierDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedCourierDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class WeightedCourierDraftDurationMinutesRangeRule: WeightedCourierDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCourierDraft) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedCourierDraftRequiredCodeRule: WeightedCourierDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCourierDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCourierDraftCodePrefixRule: WeightedCourierDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCourierDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted courier draft.
    final class WeightedCourierDraftValidator {
        var rules: [any WeightedCourierDraftRule]

        init(rules: [any WeightedCourierDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCourierDraft) -> [String] {
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

        func requireValid(_ item: WeightedCourierDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCourierDraft]) -> [String: [String]] {
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

    static func defaultWeightedCourierDraftValidator() -> WeightedCourierDraftValidator {
        return WeightedCourierDraftValidator(
            rules: [
                WeightedCourierDraftCodeLengthRule(maxLength: 1000),
                WeightedCourierDraftRequiredTitleRule(message: "weighted courier draft needs this field"),
                WeightedCourierDraftAllowedTitleRule(allowed: ["default"]),
                WeightedCourierDraftDurationMinutesRangeRule(min: 64, max: 120),
                WeightedCourierDraftRequiredCodeRule(message: "weighted courier draft needs an entry"),
                WeightedCourierDraftCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
