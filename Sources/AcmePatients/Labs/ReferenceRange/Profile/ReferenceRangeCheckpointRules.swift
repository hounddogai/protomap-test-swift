import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range checkpoint must pass. Check returns its problems, or none.
    protocol ReferenceRangeCheckpointRule {
        func check(_ item: ReferenceRangeCheckpoint) -> [String]
    }

    final class ReferenceRangeCheckpointRequiredNameRule: ReferenceRangeCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeCheckpointAllowedReviewerRule: ReferenceRangeCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is stale"]
            }
            return []
        }
    }

    final class ReferenceRangeCheckpointDiscountRangeRule: ReferenceRangeCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeCheckpoint) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeCheckpointSequenceRangeRule: ReferenceRangeCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeCheckpoint) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a reference range checkpoint.
    final class ReferenceRangeCheckpointValidator {
        var rules: [any ReferenceRangeCheckpointRule]

        init(rules: [any ReferenceRangeCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeCheckpoint) -> [String] {
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

        func requireValid(_ item: ReferenceRangeCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeCheckpoint]) -> [String: [String]] {
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

    static func defaultReferenceRangeCheckpointValidator() -> ReferenceRangeCheckpointValidator {
        return ReferenceRangeCheckpointValidator(
            rules: [
                ReferenceRangeCheckpointRequiredNameRule(message: "reference range checkpoint needs a value"),
                ReferenceRangeCheckpointAllowedReviewerRule(allowed: ["manual", "legacy"]),
                ReferenceRangeCheckpointDiscountRangeRule(min: 7.3, max: 3761.6),
                ReferenceRangeCheckpointSequenceRangeRule(min: 16, max: 120),
            ]
        )
    }
}
