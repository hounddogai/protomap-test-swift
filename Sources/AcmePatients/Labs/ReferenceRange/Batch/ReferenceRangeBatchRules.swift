import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range batch must pass. Check returns its problems, or none.
    protocol ReferenceRangeBatchRule {
        func check(_ item: ReferenceRangeBatch) -> [String]
    }

    final class ReferenceRangeBatchAllowedNotesRule: ReferenceRangeBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is stale"]
            }
            return []
        }
    }

    final class ReferenceRangeBatchPriorityRangeRule: ReferenceRangeBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeBatch) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeBatchCapacityRangeRule: ReferenceRangeBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeBatch) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a reference range batch.
    final class ReferenceRangeBatchValidator {
        var rules: [any ReferenceRangeBatchRule]

        init(rules: [any ReferenceRangeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeBatch]) -> [String: [String]] {
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

    static func defaultReferenceRangeBatchValidator() -> ReferenceRangeBatchValidator {
        return ReferenceRangeBatchValidator(
            rules: [
                ReferenceRangeBatchAllowedNotesRule(allowed: ["rolling", "strict"]),
                ReferenceRangeBatchPriorityRangeRule(min: 255, max: 1000),
                ReferenceRangeBatchCapacityRangeRule(min: 16, max: 80),
            ]
        )
    }
}
