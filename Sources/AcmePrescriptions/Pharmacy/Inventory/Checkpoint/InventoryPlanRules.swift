import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory plan must pass. Check returns its problems, or none.
    protocol InventoryPlanRule {
        func check(_ item: InventoryPlan) -> [String]
    }

    final class InventoryPlanCodePrefixRule: InventoryPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryPlanAllowedDiagnosisCodeRule: InventoryPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is out of range"]
            }
            return []
        }
    }

    final class InventoryPlanSegmentLengthRule: InventoryPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryPlan) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryPlanRequiredSegmentRule: InventoryPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryPlan) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory plan.
    final class InventoryPlanValidator {
        var rules: [any InventoryPlanRule]

        init(rules: [any InventoryPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryPlan]) -> [String: [String]] {
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

    static func defaultInventoryPlanValidator() -> InventoryPlanValidator {
        return InventoryPlanValidator(
            rules: [
                InventoryPlanCodePrefixRule(prefix: "ACM"),
                InventoryPlanAllowedDiagnosisCodeRule(allowed: ["tiered", "pending"]),
                InventoryPlanSegmentLengthRule(maxLength: 32),
                InventoryPlanRequiredSegmentRule(message: "inventory plan needs a value"),
            ]
        )
    }
}
