import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set agreement must pass. Check returns its problems, or none.
    protocol OrderSetAgreementRule {
        func check(_ item: OrderSetAgreement) -> [String]
    }

    final class OrderSetAgreementAllowedCodeRule: OrderSetAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class OrderSetAgreementActiveGuardRule: OrderSetAgreementRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OrderSetAgreement) -> [String] {
            if item.active && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class OrderSetAgreementRequiredTitleRule: OrderSetAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetAgreementCodeLengthRule: OrderSetAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set agreement.
    final class OrderSetAgreementValidator {
        var rules: [any OrderSetAgreementRule]

        init(rules: [any OrderSetAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetAgreement) -> [String] {
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

        func requireValid(_ item: OrderSetAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetAgreement]) -> [String: [String]] {
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

    static func defaultOrderSetAgreementValidator() -> OrderSetAgreementValidator {
        return OrderSetAgreementValidator(
            rules: [
                OrderSetAgreementAllowedCodeRule(allowed: ["lenient", "capped", "global"]),
                OrderSetAgreementActiveGuardRule(limit: 1000),
                OrderSetAgreementRequiredTitleRule(message: "order set agreement needs an entry"),
                OrderSetAgreementCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
