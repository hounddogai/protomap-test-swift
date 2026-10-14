import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation claim must pass. Check returns its problems, or none.
    protocol IsolationClaimRule {
        func check(_ item: IsolationClaim) -> [String]
    }

    final class IsolationClaimRequiredLabelRule: IsolationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationClaimQuantityRangeRule: IsolationClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationClaim) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationClaimCodePrefixRule: IsolationClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationClaimAllowedChecksumRule: IsolationClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is below minimum"]
            }
            return []
        }
    }

    final class IsolationClaimOwnerIDLengthRule: IsolationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationClaim) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation claim.
    final class IsolationClaimValidator {
        var rules: [any IsolationClaimRule]

        init(rules: [any IsolationClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationClaim]) -> [String: [String]] {
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

    static func defaultIsolationClaimValidator() -> IsolationClaimValidator {
        return IsolationClaimValidator(
            rules: [
                IsolationClaimRequiredLabelRule(message: "isolation claim needs a value"),
                IsolationClaimQuantityRangeRule(min: 255, max: 86400),
                IsolationClaimCodePrefixRule(prefix: "ACM"),
                IsolationClaimAllowedChecksumRule(allowed: ["batched", "pending", "batched"]),
                IsolationClaimOwnerIDLengthRule(maxLength: 32),
            ]
        )
    }
}
