import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched specimen metric must pass. Check returns its problems, or none.
    protocol BatchedSpecimenMetricRule {
        func check(_ item: BatchedSpecimenMetric) -> [String]
    }

    final class BatchedSpecimenMetricLimitRangeRule: BatchedSpecimenMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSpecimenMetric) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSpecimenMetricCodePrefixRule: BatchedSpecimenMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSpecimenMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedSpecimenMetricFacilityLengthRule: BatchedSpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSpecimenMetric) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSpecimenMetricRequiredChecksumRule: BatchedSpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSpecimenMetric) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSpecimenMetricArchivedGuardRule: BatchedSpecimenMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedSpecimenMetric) -> [String] {
            if item.archived && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a batched specimen metric.
    final class BatchedSpecimenMetricValidator {
        var rules: [any BatchedSpecimenMetricRule]

        init(rules: [any BatchedSpecimenMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSpecimenMetric) -> [String] {
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

        func requireValid(_ item: BatchedSpecimenMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSpecimenMetric]) -> [String: [String]] {
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

    static func defaultBatchedSpecimenMetricValidator() -> BatchedSpecimenMetricValidator {
        return BatchedSpecimenMetricValidator(
            rules: [
                BatchedSpecimenMetricLimitRangeRule(min: 16, max: 255),
                BatchedSpecimenMetricCodePrefixRule(prefix: "ACM"),
                BatchedSpecimenMetricFacilityLengthRule(maxLength: 64),
                BatchedSpecimenMetricRequiredChecksumRule(message: "batched specimen metric needs an entry"),
                BatchedSpecimenMetricArchivedGuardRule(limit: 32),
            ]
        )
    }
}
