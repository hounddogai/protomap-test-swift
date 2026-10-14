import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation draft must pass. Check returns its problems, or none.
    protocol IsolationDraftRule {
        func check(_ item: IsolationDraft) -> [String]
    }

    final class IsolationDraftMinimumRangeRule: IsolationDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationDraft) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationDraftRequiredNameRule: IsolationDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationDraftCopayRangeRule: IsolationDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationDraft) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a isolation draft.
    final class IsolationDraftValidator {
        var rules: [any IsolationDraftRule]

        init(rules: [any IsolationDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationDraft) -> [String] {
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

        func requireValid(_ item: IsolationDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationDraft]) -> [String: [String]] {
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

    static func defaultIsolationDraftValidator() -> IsolationDraftValidator {
        return IsolationDraftValidator(
            rules: [
                IsolationDraftMinimumRangeRule(min: 10.0, max: 1115.7),
                IsolationDraftRequiredNameRule(message: "isolation draft needs this field"),
                IsolationDraftCopayRangeRule(min: 7.5, max: 1185.2),
            ]
        )
    }
}
