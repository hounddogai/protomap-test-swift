import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched revocation target must pass. Check returns its problems, or none.
    protocol BatchedRevocationTargetRule {
        func check(_ item: BatchedRevocationTarget) -> [String]
    }

    final class BatchedRevocationTargetRequiredCategoryRule: BatchedRevocationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRevocationTarget) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRevocationTargetRequiredLabelRule: BatchedRevocationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRevocationTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRevocationTargetRequiredCodeRule: BatchedRevocationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRevocationTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched revocation target.
    final class BatchedRevocationTargetValidator {
        var rules: [any BatchedRevocationTargetRule]

        init(rules: [any BatchedRevocationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRevocationTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedRevocationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRevocationTarget]) -> [String: [String]] {
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

    static func defaultBatchedRevocationTargetValidator() -> BatchedRevocationTargetValidator {
        return BatchedRevocationTargetValidator(
            rules: [
                BatchedRevocationTargetRequiredCategoryRule(message: "batched revocation target needs a value"),
                BatchedRevocationTargetRequiredLabelRule(message: "batched revocation target needs a value"),
                BatchedRevocationTargetRequiredCodeRule(message: "batched revocation target needs an entry"),
            ]
        )
    }
}
