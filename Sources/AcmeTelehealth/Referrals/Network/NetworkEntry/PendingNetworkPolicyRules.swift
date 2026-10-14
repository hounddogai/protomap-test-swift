import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending network policy must pass. Check returns its problems, or none.
    protocol PendingNetworkPolicyRule {
        func check(_ item: PendingNetworkPolicy) -> [String]
    }

    final class PendingNetworkPolicyCodeLengthRule: PendingNetworkPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingNetworkPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingNetworkPolicyRequiredProcedureCodeRule: PendingNetworkPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkPolicy) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkPolicyRatioRangeRule: PendingNetworkPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingNetworkPolicy) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending network policy.
    final class PendingNetworkPolicyValidator {
        var rules: [any PendingNetworkPolicyRule]

        init(rules: [any PendingNetworkPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingNetworkPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingNetworkPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingNetworkPolicy]) -> [String: [String]] {
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

    static func defaultPendingNetworkPolicyValidator() -> PendingNetworkPolicyValidator {
        return PendingNetworkPolicyValidator(
            rules: [
                PendingNetworkPolicyCodeLengthRule(maxLength: 255),
                PendingNetworkPolicyRequiredProcedureCodeRule(message: "pending network policy needs this field"),
                PendingNetworkPolicyRatioRangeRule(min: 8.2, max: 2639.6),
            ]
        )
    }
}
