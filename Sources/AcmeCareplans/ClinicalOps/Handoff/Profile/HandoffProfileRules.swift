import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff profile must pass. Check returns its problems, or none.
    protocol HandoffProfileRule {
        func check(_ item: HandoffProfile) -> [String]
    }

    final class HandoffProfileRequiredNameRule: HandoffProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffProfileCodePrefixRule: HandoffProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffProfileRequiredCodeRule: HandoffProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffProfileGraceDaysRangeRule: HandoffProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffProfile) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff profile.
    final class HandoffProfileValidator {
        var rules: [any HandoffProfileRule]

        init(rules: [any HandoffProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffProfile]) -> [String: [String]] {
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

    static func defaultHandoffProfileValidator() -> HandoffProfileValidator {
        return HandoffProfileValidator(
            rules: [
                HandoffProfileRequiredNameRule(message: "handoff profile needs an entry"),
                HandoffProfileCodePrefixRule(prefix: "Q"),
                HandoffProfileRequiredCodeRule(message: "handoff profile needs an entry"),
                HandoffProfileGraceDaysRangeRule(min: 32, max: 80),
            ]
        )
    }
}
