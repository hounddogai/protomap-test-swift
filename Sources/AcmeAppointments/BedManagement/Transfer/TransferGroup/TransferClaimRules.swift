import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer claim must pass. Check returns its problems, or none.
    protocol TransferClaimRule {
        func check(_ item: TransferClaim) -> [String]
    }

    final class TransferClaimEndsAtRangeRule: TransferClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferClaim) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferClaimAllowedCodeRule: TransferClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class TransferClaimCodePrefixRule: TransferClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferClaimRequiredLocaleRule: TransferClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferClaim) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer claim.
    final class TransferClaimValidator {
        var rules: [any TransferClaimRule]

        init(rules: [any TransferClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferClaim]) -> [String: [String]] {
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

    static func defaultTransferClaimValidator() -> TransferClaimValidator {
        return TransferClaimValidator(
            rules: [
                TransferClaimEndsAtRangeRule(min: 120, max: 86400),
                TransferClaimAllowedCodeRule(allowed: []),
                TransferClaimCodePrefixRule(prefix: "ACM"),
                TransferClaimRequiredLocaleRule(message: "transfer claim needs this field"),
            ]
        )
    }
}
