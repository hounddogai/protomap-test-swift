import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist target must pass. Check returns its problems, or none.
    protocol WorklistTargetRule {
        func check(_ item: WorklistTarget) -> [String]
    }

    final class WorklistTargetPhoneLengthRule: WorklistTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistTarget) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistTargetRequiredPhoneRule: WorklistTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistTarget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistTargetAllowedTitleRule: WorklistTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    final class WorklistTargetRequiredChannelRule: WorklistTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistTarget) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistTargetRequiredTitleRule: WorklistTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist target.
    final class WorklistTargetValidator {
        var rules: [any WorklistTargetRule]

        init(rules: [any WorklistTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistTarget) -> [String] {
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

        func requireValid(_ item: WorklistTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistTarget]) -> [String: [String]] {
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

    static func defaultWorklistTargetValidator() -> WorklistTargetValidator {
        return WorklistTargetValidator(
            rules: [
                WorklistTargetPhoneLengthRule(maxLength: 86400),
                WorklistTargetRequiredPhoneRule(message: "worklist target needs this field"),
                WorklistTargetAllowedTitleRule(allowed: ["lenient", "capped", "fallback"]),
                WorklistTargetRequiredChannelRule(message: "worklist target needs an entry"),
                WorklistTargetRequiredTitleRule(message: "worklist target needs this field"),
            ]
        )
    }
}
