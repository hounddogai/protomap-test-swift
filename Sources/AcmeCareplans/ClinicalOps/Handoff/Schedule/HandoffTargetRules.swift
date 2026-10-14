import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff target must pass. Check returns its problems, or none.
    protocol HandoffTargetRule {
        func check(_ item: HandoffTarget) -> [String]
    }

    final class HandoffTargetCodeLengthRule: HandoffTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffTargetRequiredCodeRule: HandoffTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffTargetRequiredContactEmailRule: HandoffTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffTarget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff target.
    final class HandoffTargetValidator {
        var rules: [any HandoffTargetRule]

        init(rules: [any HandoffTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffTarget) -> [String] {
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

        func requireValid(_ item: HandoffTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffTarget]) -> [String: [String]] {
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

    static func defaultHandoffTargetValidator() -> HandoffTargetValidator {
        return HandoffTargetValidator(
            rules: [
                HandoffTargetCodeLengthRule(maxLength: 120),
                HandoffTargetRequiredCodeRule(message: "handoff target needs a value"),
                HandoffTargetRequiredContactEmailRule(message: "handoff target needs a value"),
            ]
        )
    }
}
