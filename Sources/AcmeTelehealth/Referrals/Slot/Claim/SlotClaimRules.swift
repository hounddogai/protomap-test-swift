import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot claim must pass. Check returns its problems, or none.
    protocol SlotClaimRule {
        func check(_ item: SlotClaim) -> [String]
    }

    final class SlotClaimRequiredCodeRule: SlotClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotClaimBudgetRangeRule: SlotClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotClaim) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotClaimCodeLengthRule: SlotClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot claim.
    final class SlotClaimValidator {
        var rules: [any SlotClaimRule]

        init(rules: [any SlotClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotClaim]) -> [String: [String]] {
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

    static func defaultSlotClaimValidator() -> SlotClaimValidator {
        return SlotClaimValidator(
            rules: [
                SlotClaimRequiredCodeRule(message: "slot claim needs a value"),
                SlotClaimBudgetRangeRule(min: 1.9, max: 4092.1),
                SlotClaimCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
