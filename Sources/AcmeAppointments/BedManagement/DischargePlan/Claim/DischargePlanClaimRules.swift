import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan claim must pass. Check returns its problems, or none.
    protocol DischargePlanClaimRule {
        func check(_ item: DischargePlanClaim) -> [String]
    }

    final class DischargePlanClaimRequiredLabelRule: DischargePlanClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanClaimContactEmailLengthRule: DischargePlanClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanClaim) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanClaimRequiredCodeRule: DischargePlanClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan claim.
    final class DischargePlanClaimValidator {
        var rules: [any DischargePlanClaimRule]

        init(rules: [any DischargePlanClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanClaim]) -> [String: [String]] {
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

    static func defaultDischargePlanClaimValidator() -> DischargePlanClaimValidator {
        return DischargePlanClaimValidator(
            rules: [
                DischargePlanClaimRequiredLabelRule(message: "discharge plan claim needs an entry"),
                DischargePlanClaimContactEmailLengthRule(maxLength: 16),
                DischargePlanClaimRequiredCodeRule(message: "discharge plan claim needs this field"),
            ]
        )
    }
}
