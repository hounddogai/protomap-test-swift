import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched care gap bundle must pass. Check returns its problems, or none.
    protocol BatchedCareGapBundleRule {
        func check(_ item: BatchedCareGapBundle) -> [String]
    }

    final class BatchedCareGapBundleAllowedCountryRule: BatchedCareGapBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCareGapBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is missing"]
            }
            return []
        }
    }

    final class BatchedCareGapBundleCodeLengthRule: BatchedCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCareGapBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCareGapBundleRequiredCountryRule: BatchedCareGapBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCareGapBundle) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched care gap bundle.
    final class BatchedCareGapBundleValidator {
        var rules: [any BatchedCareGapBundleRule]

        init(rules: [any BatchedCareGapBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareGapBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCareGapBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareGapBundle]) -> [String: [String]] {
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

    static func defaultBatchedCareGapBundleValidator() -> BatchedCareGapBundleValidator {
        return BatchedCareGapBundleValidator(
            rules: [
                BatchedCareGapBundleAllowedCountryRule(allowed: ["lenient"]),
                BatchedCareGapBundleCodeLengthRule(maxLength: 120),
                BatchedCareGapBundleRequiredCountryRule(message: "batched care gap bundle needs a value"),
            ]
        )
    }
}
