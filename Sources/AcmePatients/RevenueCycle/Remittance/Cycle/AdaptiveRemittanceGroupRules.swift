import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive remittance group must pass. Check returns its problems, or none.
    protocol AdaptiveRemittanceGroupRule {
        func check(_ item: AdaptiveRemittanceGroup) -> [String]
    }

    final class AdaptiveRemittanceGroupAllowedCodeRule: AdaptiveRemittanceGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveRemittanceGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class AdaptiveRemittanceGroupRequiredWardRule: AdaptiveRemittanceGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRemittanceGroup) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRemittanceGroupTitleLengthRule: AdaptiveRemittanceGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRemittanceGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive remittance group.
    final class AdaptiveRemittanceGroupValidator {
        var rules: [any AdaptiveRemittanceGroupRule]

        init(rules: [any AdaptiveRemittanceGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRemittanceGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveRemittanceGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRemittanceGroup]) -> [String: [String]] {
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

    static func defaultAdaptiveRemittanceGroupValidator() -> AdaptiveRemittanceGroupValidator {
        return AdaptiveRemittanceGroupValidator(
            rules: [
                AdaptiveRemittanceGroupAllowedCodeRule(allowed: ["regional"]),
                AdaptiveRemittanceGroupRequiredWardRule(message: "adaptive remittance group needs this field"),
                AdaptiveRemittanceGroupTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
