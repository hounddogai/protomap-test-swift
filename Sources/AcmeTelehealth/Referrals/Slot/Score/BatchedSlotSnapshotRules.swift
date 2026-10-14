import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot snapshot must pass. Check returns its problems, or none.
    protocol BatchedSlotSnapshotRule {
        func check(_ item: BatchedSlotSnapshot) -> [String]
    }

    final class BatchedSlotSnapshotCodeLengthRule: BatchedSlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotSnapshotRequiredCodeRule: BatchedSlotSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSlotSnapshotChannelLengthRule: BatchedSlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotSnapshot) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotSnapshotRequiredChannelRule: BatchedSlotSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotSnapshot) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSlotSnapshotAmountRangeRule: BatchedSlotSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotSnapshot) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSlotSnapshotPriorityRangeRule: BatchedSlotSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotSnapshot) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched slot snapshot.
    final class BatchedSlotSnapshotValidator {
        var rules: [any BatchedSlotSnapshotRule]

        init(rules: [any BatchedSlotSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSlotSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotSnapshot]) -> [String: [String]] {
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

    static func defaultBatchedSlotSnapshotValidator() -> BatchedSlotSnapshotValidator {
        return BatchedSlotSnapshotValidator(
            rules: [
                BatchedSlotSnapshotCodeLengthRule(maxLength: 32),
                BatchedSlotSnapshotRequiredCodeRule(message: "batched slot snapshot needs this field"),
                BatchedSlotSnapshotChannelLengthRule(maxLength: 3600),
                BatchedSlotSnapshotRequiredChannelRule(message: "batched slot snapshot needs an entry"),
                BatchedSlotSnapshotAmountRangeRule(min: 7.4, max: 3884.8),
                BatchedSlotSnapshotPriorityRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
