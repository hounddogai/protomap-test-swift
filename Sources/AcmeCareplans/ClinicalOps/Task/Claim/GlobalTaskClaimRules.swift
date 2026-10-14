import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global task claim must pass. Check returns its problems, or none.
    protocol GlobalTaskClaimRule {
        func check(_ item: GlobalTaskClaim) -> [String]
    }

    final class GlobalTaskClaimCodePrefixRule: GlobalTaskClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalTaskClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalTaskClaimRequiredCodeRule: GlobalTaskClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTaskClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTaskClaimCostRangeRule: GlobalTaskClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalTaskClaim) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalTaskClaimLabelLengthRule: GlobalTaskClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTaskClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global task claim.
    final class GlobalTaskClaimValidator {
        var rules: [any GlobalTaskClaimRule]

        init(rules: [any GlobalTaskClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalTaskClaim) -> [String] {
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

        func requireValid(_ item: GlobalTaskClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalTaskClaim]) -> [String: [String]] {
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

    static func defaultGlobalTaskClaimValidator() -> GlobalTaskClaimValidator {
        return GlobalTaskClaimValidator(
            rules: [
                GlobalTaskClaimCodePrefixRule(prefix: "ACM"),
                GlobalTaskClaimRequiredCodeRule(message: "global task claim needs a value"),
                GlobalTaskClaimCostRangeRule(min: 2.2, max: 2569.8),
                GlobalTaskClaimLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
