import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched accession estimate must pass. Check returns its problems, or none.
    protocol BatchedAccessionEstimateRule {
        func check(_ item: BatchedAccessionEstimate) -> [String]
    }

    final class BatchedAccessionEstimateActiveGuardRule: BatchedAccessionEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedAccessionEstimate) -> [String] {
            if item.active && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class BatchedAccessionEstimateRequiredTitleRule: BatchedAccessionEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionEstimateCodeLengthRule: BatchedAccessionEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAccessionEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAccessionEstimateCountryLengthRule: BatchedAccessionEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAccessionEstimate) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAccessionEstimateTitleLengthRule: BatchedAccessionEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAccessionEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAccessionEstimateAllowedPatientRefRule: BatchedAccessionEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedAccessionEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a batched accession estimate.
    final class BatchedAccessionEstimateValidator {
        var rules: [any BatchedAccessionEstimateRule]

        init(rules: [any BatchedAccessionEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAccessionEstimate) -> [String] {
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

        func requireValid(_ item: BatchedAccessionEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAccessionEstimate]) -> [String: [String]] {
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

    static func defaultBatchedAccessionEstimateValidator() -> BatchedAccessionEstimateValidator {
        return BatchedAccessionEstimateValidator(
            rules: [
                BatchedAccessionEstimateActiveGuardRule(limit: 32),
                BatchedAccessionEstimateRequiredTitleRule(message: "batched accession estimate needs an entry"),
                BatchedAccessionEstimateCodeLengthRule(maxLength: 1000),
                BatchedAccessionEstimateCountryLengthRule(maxLength: 16),
                BatchedAccessionEstimateTitleLengthRule(maxLength: 1000),
                BatchedAccessionEstimateAllowedPatientRefRule(allowed: ["rolling", "regional"]),
            ]
        )
    }
}
