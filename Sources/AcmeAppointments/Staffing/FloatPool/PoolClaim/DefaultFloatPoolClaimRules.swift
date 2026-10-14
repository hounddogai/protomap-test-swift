import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default float pool claim must pass. Check returns its problems, or none.
    protocol DefaultFloatPoolClaimRule {
        func check(_ item: DefaultFloatPoolClaim) -> [String]
    }

    final class DefaultFloatPoolClaimRequiredCodeRule: DefaultFloatPoolClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolClaimChannelLengthRule: DefaultFloatPoolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolClaim) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolClaimRequiredLabelRule: DefaultFloatPoolClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolClaimCodeLengthRule: DefaultFloatPoolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default float pool claim.
    final class DefaultFloatPoolClaimValidator {
        var rules: [any DefaultFloatPoolClaimRule]

        init(rules: [any DefaultFloatPoolClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFloatPoolClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultFloatPoolClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFloatPoolClaim]) -> [String: [String]] {
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

    static func defaultDefaultFloatPoolClaimValidator() -> DefaultFloatPoolClaimValidator {
        return DefaultFloatPoolClaimValidator(
            rules: [
                DefaultFloatPoolClaimRequiredCodeRule(message: "default float pool claim needs an entry"),
                DefaultFloatPoolClaimChannelLengthRule(maxLength: 16),
                DefaultFloatPoolClaimRequiredLabelRule(message: "default float pool claim needs an entry"),
                DefaultFloatPoolClaimCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
