import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff window must pass. Check returns its problems, or none.
    protocol HandoffWindowRule {
        func check(_ item: HandoffWindow) -> [String]
    }

    final class HandoffWindowRequiredLabelRule: HandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffWindowActiveGuardRule: HandoffWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffWindow) -> [String] {
            if item.active && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class HandoffWindowRetriesRangeRule: HandoffWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffWindow) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffWindowLabelLengthRule: HandoffWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffWindowAllowedLabelRule: HandoffWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff window.
    final class HandoffWindowValidator {
        var rules: [any HandoffWindowRule]

        init(rules: [any HandoffWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffWindow]) -> [String: [String]] {
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

    static func defaultHandoffWindowValidator() -> HandoffWindowValidator {
        return HandoffWindowValidator(
            rules: [
                HandoffWindowRequiredLabelRule(message: "handoff window needs an entry"),
                HandoffWindowActiveGuardRule(limit: 86400),
                HandoffWindowRetriesRangeRule(min: 120, max: 1000),
                HandoffWindowLabelLengthRule(maxLength: 32),
                HandoffWindowAllowedLabelRule(allowed: ["manual", "regional", "manual"]),
            ]
        )
    }
}
