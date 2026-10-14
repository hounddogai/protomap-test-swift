import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched goal snapshot must pass. Check returns its problems, or none.
    protocol BatchedGoalSnapshotRule {
        func check(_ item: BatchedGoalSnapshot) -> [String]
    }

    final class BatchedGoalSnapshotRequiredCodeRule: BatchedGoalSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedGoalSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedGoalSnapshotDiscountRangeRule: BatchedGoalSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedGoalSnapshot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedGoalSnapshotTitleLengthRule: BatchedGoalSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedGoalSnapshotRequiredSegmentRule: BatchedGoalSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedGoalSnapshot) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched goal snapshot.
    final class BatchedGoalSnapshotValidator {
        var rules: [any BatchedGoalSnapshotRule]

        init(rules: [any BatchedGoalSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedGoalSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedGoalSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedGoalSnapshot]) -> [String: [String]] {
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

    static func defaultBatchedGoalSnapshotValidator() -> BatchedGoalSnapshotValidator {
        return BatchedGoalSnapshotValidator(
            rules: [
                BatchedGoalSnapshotRequiredCodeRule(message: "batched goal snapshot needs this field"),
                BatchedGoalSnapshotDiscountRangeRule(min: 8.6, max: 4748.5),
                BatchedGoalSnapshotTitleLengthRule(maxLength: 3600),
                BatchedGoalSnapshotRequiredSegmentRule(message: "batched goal snapshot needs this field"),
            ]
        )
    }
}
