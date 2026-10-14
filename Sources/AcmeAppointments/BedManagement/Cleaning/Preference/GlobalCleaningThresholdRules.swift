import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global cleaning threshold must pass. Check returns its problems, or none.
    protocol GlobalCleaningThresholdRule {
        func check(_ item: GlobalCleaningThreshold) -> [String]
    }

    final class GlobalCleaningThresholdRetriesRangeRule: GlobalCleaningThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCleaningThreshold) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalCleaningThresholdAllowedSummaryRule: GlobalCleaningThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalCleaningThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is expired"]
            }
            return []
        }
    }

    final class GlobalCleaningThresholdBedLengthRule: GlobalCleaningThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCleaningThreshold) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global cleaning threshold.
    final class GlobalCleaningThresholdValidator {
        var rules: [any GlobalCleaningThresholdRule]

        init(rules: [any GlobalCleaningThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCleaningThreshold) -> [String] {
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

        func requireValid(_ item: GlobalCleaningThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCleaningThreshold]) -> [String: [String]] {
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

    static func defaultGlobalCleaningThresholdValidator() -> GlobalCleaningThresholdValidator {
        return GlobalCleaningThresholdValidator(
            rules: [
                GlobalCleaningThresholdRetriesRangeRule(min: 16, max: 32),
                GlobalCleaningThresholdAllowedSummaryRule(allowed: []),
                GlobalCleaningThresholdBedLengthRule(maxLength: 64),
            ]
        )
    }
}
