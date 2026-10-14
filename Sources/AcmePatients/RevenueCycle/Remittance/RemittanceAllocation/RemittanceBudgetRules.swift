import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance budget must pass. Check returns its problems, or none.
    protocol RemittanceBudgetRule {
        func check(_ item: RemittanceBudget) -> [String]
    }

    final class RemittanceBudgetAllowedSummaryRule: RemittanceBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is too long"]
            }
            return []
        }
    }

    final class RemittanceBudgetDescriptionLengthRule: RemittanceBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceBudget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceBudgetRegionLengthRule: RemittanceBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceBudget) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceBudgetCodePrefixRule: RemittanceBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance budget.
    final class RemittanceBudgetValidator {
        var rules: [any RemittanceBudgetRule]

        init(rules: [any RemittanceBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceBudget]) -> [String: [String]] {
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

    static func defaultRemittanceBudgetValidator() -> RemittanceBudgetValidator {
        return RemittanceBudgetValidator(
            rules: [
                RemittanceBudgetAllowedSummaryRule(allowed: ["tiered", "pending", "primary"]),
                RemittanceBudgetDescriptionLengthRule(maxLength: 255),
                RemittanceBudgetRegionLengthRule(maxLength: 64),
                RemittanceBudgetCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
