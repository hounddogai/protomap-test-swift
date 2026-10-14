import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict read draft must pass. Check returns its problems, or none.
    protocol StrictReadDraftRule {
        func check(_ item: StrictReadDraft) -> [String]
    }

    final class StrictReadDraftStartsAtRangeRule: StrictReadDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReadDraft) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictReadDraftSequenceRangeRule: StrictReadDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReadDraft) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictReadDraftMaximumRangeRule: StrictReadDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReadDraft) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictReadDraftRequiredCodeRule: StrictReadDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict read draft.
    final class StrictReadDraftValidator {
        var rules: [any StrictReadDraftRule]

        init(rules: [any StrictReadDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReadDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictReadDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReadDraft]) -> [String: [String]] {
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

    static func defaultStrictReadDraftValidator() -> StrictReadDraftValidator {
        return StrictReadDraftValidator(
            rules: [
                StrictReadDraftStartsAtRangeRule(min: 64, max: 80),
                StrictReadDraftSequenceRangeRule(min: 1000, max: 86400),
                StrictReadDraftMaximumRangeRule(min: 4.5, max: 1162.3),
                StrictReadDraftRequiredCodeRule(message: "strict read draft needs an entry"),
            ]
        )
    }
}
