import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched bed board cycle must pass. Check returns its problems, or none.
    protocol BatchedBedBoardCycleRule {
        func check(_ item: BatchedBedBoardCycle) -> [String]
    }

    final class BatchedBedBoardCycleBatchSizeRangeRule: BatchedBedBoardCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedBedBoardCycle) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedBedBoardCycleCreatedAtRangeRule: BatchedBedBoardCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedBedBoardCycle) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedBedBoardCycleRequiredCodeRule: BatchedBedBoardCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedBedBoardCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedBedBoardCycleAllowedCodeRule: BatchedBedBoardCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedBedBoardCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a batched bed board cycle.
    final class BatchedBedBoardCycleValidator {
        var rules: [any BatchedBedBoardCycleRule]

        init(rules: [any BatchedBedBoardCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedBedBoardCycle) -> [String] {
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

        func requireValid(_ item: BatchedBedBoardCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedBedBoardCycle]) -> [String: [String]] {
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

    static func defaultBatchedBedBoardCycleValidator() -> BatchedBedBoardCycleValidator {
        return BatchedBedBoardCycleValidator(
            rules: [
                BatchedBedBoardCycleBatchSizeRangeRule(min: 1000, max: 86400),
                BatchedBedBoardCycleCreatedAtRangeRule(min: 255, max: 3600),
                BatchedBedBoardCycleRequiredCodeRule(message: "batched bed board cycle needs an entry"),
                BatchedBedBoardCycleAllowedCodeRule(allowed: ["capped", "lenient", "strict"]),
            ]
        )
    }
}
