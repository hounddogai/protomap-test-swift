import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched skill mix cycle must pass. Check returns its problems, or none.
    protocol BatchedSkillMixCycleRule {
        func check(_ item: BatchedSkillMixCycle) -> [String]
    }

    final class BatchedSkillMixCycleAcuityRangeRule: BatchedSkillMixCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSkillMixCycle) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedSkillMixCycleTitleLengthRule: BatchedSkillMixCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSkillMixCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSkillMixCycleRequiredTitleRule: BatchedSkillMixCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSkillMixCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSkillMixCycleCodePrefixRule: BatchedSkillMixCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSkillMixCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedSkillMixCycleThresholdRangeRule: BatchedSkillMixCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSkillMixCycle) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedSkillMixCycleRequiredCodeRule: BatchedSkillMixCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSkillMixCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched skill mix cycle.
    final class BatchedSkillMixCycleValidator {
        var rules: [any BatchedSkillMixCycleRule]

        init(rules: [any BatchedSkillMixCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSkillMixCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSkillMixCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSkillMixCycle]) -> [String: [String]] {
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

    static func defaultBatchedSkillMixCycleValidator() -> BatchedSkillMixCycleValidator {
        return BatchedSkillMixCycleValidator(
            rules: [
                BatchedSkillMixCycleAcuityRangeRule(min: 120, max: 3600),
                BatchedSkillMixCycleTitleLengthRule(maxLength: 80),
                BatchedSkillMixCycleRequiredTitleRule(message: "batched skill mix cycle needs an entry"),
                BatchedSkillMixCycleCodePrefixRule(prefix: "OPS"),
                BatchedSkillMixCycleThresholdRangeRule(min: 3.1, max: 181.2),
                BatchedSkillMixCycleRequiredCodeRule(message: "batched skill mix cycle needs this field"),
            ]
        )
    }
}
