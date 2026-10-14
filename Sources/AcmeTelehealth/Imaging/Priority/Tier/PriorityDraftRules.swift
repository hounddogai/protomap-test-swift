import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority draft must pass. Check returns its problems, or none.
    protocol PriorityDraftRule {
        func check(_ item: PriorityDraft) -> [String]
    }

    final class PriorityDraftRequiredNameRule: PriorityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityDraftVisitMinutesRangeRule: PriorityDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityDraft) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityDraftRequiredLabelRule: PriorityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityDraftCodeLengthRule: PriorityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityDraftRequiredTitleRule: PriorityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityDraftRatioRangeRule: PriorityDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityDraft) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority draft.
    final class PriorityDraftValidator {
        var rules: [any PriorityDraftRule]

        init(rules: [any PriorityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityDraft) -> [String] {
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

        func requireValid(_ item: PriorityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityDraft]) -> [String: [String]] {
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

    static func defaultPriorityDraftValidator() -> PriorityDraftValidator {
        return PriorityDraftValidator(
            rules: [
                PriorityDraftRequiredNameRule(message: "priority draft needs a value"),
                PriorityDraftVisitMinutesRangeRule(min: 3600, max: 3600),
                PriorityDraftRequiredLabelRule(message: "priority draft needs this field"),
                PriorityDraftCodeLengthRule(maxLength: 120),
                PriorityDraftRequiredTitleRule(message: "priority draft needs an entry"),
                PriorityDraftRatioRangeRule(min: 7.3, max: 1804.8),
            ]
        )
    }
}
