import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool allocation must pass. Check returns its problems, or none.
    protocol FloatPoolAllocationRule {
        func check(_ item: FloatPoolAllocation) -> [String]
    }

    final class FloatPoolAllocationTitleLengthRule: FloatPoolAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolAllocationCodeLengthRule: FloatPoolAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolAllocationRequiredWardRule: FloatPoolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolAllocation) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolAllocationBatchSizeRangeRule: FloatPoolAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolAllocation) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolAllocationArchivedGuardRule: FloatPoolAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FloatPoolAllocation) -> [String] {
            if item.archived && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FloatPoolAllocationRequiredDescriptionRule: FloatPoolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolAllocation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a float pool allocation.
    final class FloatPoolAllocationValidator {
        var rules: [any FloatPoolAllocationRule]

        init(rules: [any FloatPoolAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolAllocation]) -> [String: [String]] {
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

    static func defaultFloatPoolAllocationValidator() -> FloatPoolAllocationValidator {
        return FloatPoolAllocationValidator(
            rules: [
                FloatPoolAllocationTitleLengthRule(maxLength: 3600),
                FloatPoolAllocationCodeLengthRule(maxLength: 16),
                FloatPoolAllocationRequiredWardRule(message: "float pool allocation needs an entry"),
                FloatPoolAllocationBatchSizeRangeRule(min: 80, max: 120),
                FloatPoolAllocationArchivedGuardRule(limit: 32),
                FloatPoolAllocationRequiredDescriptionRule(message: "float pool allocation needs an entry"),
            ]
        )
    }
}
