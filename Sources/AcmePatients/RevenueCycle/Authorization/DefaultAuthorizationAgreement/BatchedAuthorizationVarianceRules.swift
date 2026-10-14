import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched authorization variance must pass. Check returns its problems, or none.
    protocol BatchedAuthorizationVarianceRule {
        func check(_ item: BatchedAuthorizationVariance) -> [String]
    }

    final class BatchedAuthorizationVarianceAllowedLabelRule: BatchedAuthorizationVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedAuthorizationVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class BatchedAuthorizationVarianceRequiredEncounterIDRule: BatchedAuthorizationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationVariance) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationVarianceCodeLengthRule: BatchedAuthorizationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAuthorizationVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationVarianceThresholdRangeRule: BatchedAuthorizationVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAuthorizationVariance) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedAuthorizationVarianceLabelLengthRule: BatchedAuthorizationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAuthorizationVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched authorization variance.
    final class BatchedAuthorizationVarianceValidator {
        var rules: [any BatchedAuthorizationVarianceRule]

        init(rules: [any BatchedAuthorizationVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAuthorizationVariance) -> [String] {
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

        func requireValid(_ item: BatchedAuthorizationVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAuthorizationVariance]) -> [String: [String]] {
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

    static func defaultBatchedAuthorizationVarianceValidator() -> BatchedAuthorizationVarianceValidator {
        return BatchedAuthorizationVarianceValidator(
            rules: [
                BatchedAuthorizationVarianceAllowedLabelRule(allowed: ["seasonal", "manual"]),
                BatchedAuthorizationVarianceRequiredEncounterIDRule(
                    message: "batched authorization variance needs an entry"
                ),
                BatchedAuthorizationVarianceCodeLengthRule(maxLength: 255),
                BatchedAuthorizationVarianceThresholdRangeRule(min: 0.7, max: 856.2),
                BatchedAuthorizationVarianceLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
