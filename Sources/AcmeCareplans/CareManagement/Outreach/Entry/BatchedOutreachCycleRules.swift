import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched outreach cycle must pass. Check returns its problems, or none.
    protocol BatchedOutreachCycleRule {
        func check(_ item: BatchedOutreachCycle) -> [String]
    }

    final class BatchedOutreachCycleRequiredEncounterIDRule: BatchedOutreachCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOutreachCycle) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOutreachCycleCodePrefixRule: BatchedOutreachCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedOutreachCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedOutreachCycleBatchSizeRangeRule: BatchedOutreachCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOutreachCycle) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched outreach cycle.
    final class BatchedOutreachCycleValidator {
        var rules: [any BatchedOutreachCycleRule]

        init(rules: [any BatchedOutreachCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOutreachCycle) -> [String] {
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

        func requireValid(_ item: BatchedOutreachCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOutreachCycle]) -> [String: [String]] {
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

    static func defaultBatchedOutreachCycleValidator() -> BatchedOutreachCycleValidator {
        return BatchedOutreachCycleValidator(
            rules: [
                BatchedOutreachCycleRequiredEncounterIDRule(message: "batched outreach cycle needs a value"),
                BatchedOutreachCycleCodePrefixRule(prefix: "ACM"),
                BatchedOutreachCycleBatchSizeRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
