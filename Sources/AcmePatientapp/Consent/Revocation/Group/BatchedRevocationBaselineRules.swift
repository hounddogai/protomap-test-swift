import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched revocation baseline must pass. Check returns its problems, or none.
    protocol BatchedRevocationBaselineRule {
        func check(_ item: BatchedRevocationBaseline) -> [String]
    }

    final class BatchedRevocationBaselineRequiredClinicianIDRule: BatchedRevocationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRevocationBaseline) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRevocationBaselineRequiredTitleRule: BatchedRevocationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRevocationBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRevocationBaselineAllowedCategoryRule: BatchedRevocationBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedRevocationBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a batched revocation baseline.
    final class BatchedRevocationBaselineValidator {
        var rules: [any BatchedRevocationBaselineRule]

        init(rules: [any BatchedRevocationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRevocationBaseline) -> [String] {
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

        func requireValid(_ item: BatchedRevocationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRevocationBaseline]) -> [String: [String]] {
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

    static func defaultBatchedRevocationBaselineValidator() -> BatchedRevocationBaselineValidator {
        return BatchedRevocationBaselineValidator(
            rules: [
                BatchedRevocationBaselineRequiredClinicianIDRule(
                    message: "batched revocation baseline needs an entry"
                ),
                BatchedRevocationBaselineRequiredTitleRule(message: "batched revocation baseline needs a value"),
                BatchedRevocationBaselineAllowedCategoryRule(allowed: ["pending", "manual", "manual"]),
            ]
        )
    }
}
