import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched dispense bundle must pass. Check returns its problems, or none.
    protocol BatchedDispenseBundleRule {
        func check(_ item: BatchedDispenseBundle) -> [String]
    }

    final class BatchedDispenseBundleFacilityLengthRule: BatchedDispenseBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDispenseBundle) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDispenseBundleRequiredRegionRule: BatchedDispenseBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDispenseBundle) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDispenseBundleCreatedAtRangeRule: BatchedDispenseBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispenseBundle) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched dispense bundle.
    final class BatchedDispenseBundleValidator {
        var rules: [any BatchedDispenseBundleRule]

        init(rules: [any BatchedDispenseBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDispenseBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDispenseBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDispenseBundle]) -> [String: [String]] {
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

    static func defaultBatchedDispenseBundleValidator() -> BatchedDispenseBundleValidator {
        return BatchedDispenseBundleValidator(
            rules: [
                BatchedDispenseBundleFacilityLengthRule(maxLength: 16),
                BatchedDispenseBundleRequiredRegionRule(message: "batched dispense bundle needs an entry"),
                BatchedDispenseBundleCreatedAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
