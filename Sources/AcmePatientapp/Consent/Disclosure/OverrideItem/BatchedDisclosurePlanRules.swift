import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched disclosure plan must pass. Check returns its problems, or none.
    protocol BatchedDisclosurePlanRule {
        func check(_ item: BatchedDisclosurePlan) -> [String]
    }

    final class BatchedDisclosurePlanAllowedWardRule: BatchedDisclosurePlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedDisclosurePlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is stale"]
            }
            return []
        }
    }

    final class BatchedDisclosurePlanCodeLengthRule: BatchedDisclosurePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosurePlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosurePlanPhoneLengthRule: BatchedDisclosurePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosurePlan) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched disclosure plan.
    final class BatchedDisclosurePlanValidator {
        var rules: [any BatchedDisclosurePlanRule]

        init(rules: [any BatchedDisclosurePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDisclosurePlan) -> [String] {
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

        func requireValid(_ item: BatchedDisclosurePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDisclosurePlan]) -> [String: [String]] {
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

    static func defaultBatchedDisclosurePlanValidator() -> BatchedDisclosurePlanValidator {
        return BatchedDisclosurePlanValidator(
            rules: [
                BatchedDisclosurePlanAllowedWardRule(allowed: ["lenient", "rolling"]),
                BatchedDisclosurePlanCodeLengthRule(maxLength: 120),
                BatchedDisclosurePlanPhoneLengthRule(maxLength: 1000),
            ]
        )
    }
}
