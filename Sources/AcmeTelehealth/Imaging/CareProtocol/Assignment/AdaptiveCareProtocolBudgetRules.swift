import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive care protocol budget must pass. Check returns its problems, or none.
    protocol AdaptiveCareProtocolBudgetRule {
        func check(_ item: AdaptiveCareProtocolBudget) -> [String]
    }

    final class AdaptiveCareProtocolBudgetRequiredCodeRule: AdaptiveCareProtocolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareProtocolBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolBudgetCodeLengthRule: AdaptiveCareProtocolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolBudgetAllowedUnitRule: AdaptiveCareProtocolBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCareProtocolBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is above maximum"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolBudgetRequiredChecksumRule: AdaptiveCareProtocolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareProtocolBudget) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care protocol budget.
    final class AdaptiveCareProtocolBudgetValidator {
        var rules: [any AdaptiveCareProtocolBudgetRule]

        init(rules: [any AdaptiveCareProtocolBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareProtocolBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCareProtocolBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareProtocolBudget]) -> [String: [String]] {
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

    static func defaultAdaptiveCareProtocolBudgetValidator() -> AdaptiveCareProtocolBudgetValidator {
        return AdaptiveCareProtocolBudgetValidator(
            rules: [
                AdaptiveCareProtocolBudgetRequiredCodeRule(message: "adaptive care protocol budget needs this field"),
                AdaptiveCareProtocolBudgetCodeLengthRule(maxLength: 120),
                AdaptiveCareProtocolBudgetAllowedUnitRule(allowed: ["legacy", "batched", "adaptive"]),
                AdaptiveCareProtocolBudgetRequiredChecksumRule(
                    message: "adaptive care protocol budget needs this field"
                ),
            ]
        )
    }
}
