import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict authorization slot must pass. Check returns its problems, or none.
    protocol StrictAuthorizationSlotRule {
        func check(_ item: StrictAuthorizationSlot) -> [String]
    }

    final class StrictAuthorizationSlotPayerLengthRule: StrictAuthorizationSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAuthorizationSlot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAuthorizationSlotRequiredCodeRule: StrictAuthorizationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAuthorizationSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAuthorizationSlotRequiredPayerRule: StrictAuthorizationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAuthorizationSlot) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict authorization slot.
    final class StrictAuthorizationSlotValidator {
        var rules: [any StrictAuthorizationSlotRule]

        init(rules: [any StrictAuthorizationSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAuthorizationSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictAuthorizationSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAuthorizationSlot]) -> [String: [String]] {
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

    static func defaultStrictAuthorizationSlotValidator() -> StrictAuthorizationSlotValidator {
        return StrictAuthorizationSlotValidator(
            rules: [
                StrictAuthorizationSlotPayerLengthRule(maxLength: 80),
                StrictAuthorizationSlotRequiredCodeRule(message: "strict authorization slot needs a value"),
                StrictAuthorizationSlotRequiredPayerRule(message: "strict authorization slot needs a value"),
            ]
        )
    }
}
