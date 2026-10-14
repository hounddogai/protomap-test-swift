import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped float pool assignment must pass. Check returns its problems, or none.
    protocol CappedFloatPoolAssignmentRule {
        func check(_ item: CappedFloatPoolAssignment) -> [String]
    }

    final class CappedFloatPoolAssignmentRequiredCodeRule: CappedFloatPoolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFloatPoolAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFloatPoolAssignmentRequiredSegmentRule: CappedFloatPoolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFloatPoolAssignment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFloatPoolAssignmentBatchSizeRangeRule: CappedFloatPoolAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFloatPoolAssignment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedFloatPoolAssignmentCodeLengthRule: CappedFloatPoolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFloatPoolAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFloatPoolAssignmentRequiredContactEmailRule: CappedFloatPoolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFloatPoolAssignment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFloatPoolAssignmentSegmentLengthRule: CappedFloatPoolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFloatPoolAssignment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped float pool assignment.
    final class CappedFloatPoolAssignmentValidator {
        var rules: [any CappedFloatPoolAssignmentRule]

        init(rules: [any CappedFloatPoolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFloatPoolAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedFloatPoolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFloatPoolAssignment]) -> [String: [String]] {
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

    static func defaultCappedFloatPoolAssignmentValidator() -> CappedFloatPoolAssignmentValidator {
        return CappedFloatPoolAssignmentValidator(
            rules: [
                CappedFloatPoolAssignmentRequiredCodeRule(message: "capped float pool assignment needs a value"),
                CappedFloatPoolAssignmentRequiredSegmentRule(message: "capped float pool assignment needs a value"),
                CappedFloatPoolAssignmentBatchSizeRangeRule(min: 64, max: 64),
                CappedFloatPoolAssignmentCodeLengthRule(maxLength: 86400),
                CappedFloatPoolAssignmentRequiredContactEmailRule(
                    message: "capped float pool assignment needs an entry"
                ),
                CappedFloatPoolAssignmentSegmentLengthRule(maxLength: 120),
            ]
        )
    }
}
