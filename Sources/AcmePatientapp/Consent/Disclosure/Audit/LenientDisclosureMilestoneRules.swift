import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient disclosure milestone must pass. Check returns its problems, or none.
    protocol LenientDisclosureMilestoneRule {
        func check(_ item: LenientDisclosureMilestone) -> [String]
    }

    final class LenientDisclosureMilestoneMaximumRangeRule: LenientDisclosureMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDisclosureMilestone) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientDisclosureMilestoneRequiredCodeRule: LenientDisclosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDisclosureMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDisclosureMilestoneCodeLengthRule: LenientDisclosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDisclosureMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDisclosureMilestoneWardLengthRule: LenientDisclosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDisclosureMilestone) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDisclosureMilestoneRequiredLabelRule: LenientDisclosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDisclosureMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient disclosure milestone.
    final class LenientDisclosureMilestoneValidator {
        var rules: [any LenientDisclosureMilestoneRule]

        init(rules: [any LenientDisclosureMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDisclosureMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDisclosureMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDisclosureMilestone]) -> [String: [String]] {
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

    static func defaultLenientDisclosureMilestoneValidator() -> LenientDisclosureMilestoneValidator {
        return LenientDisclosureMilestoneValidator(
            rules: [
                LenientDisclosureMilestoneMaximumRangeRule(min: 1.7, max: 2154.0),
                LenientDisclosureMilestoneRequiredCodeRule(message: "lenient disclosure milestone needs a value"),
                LenientDisclosureMilestoneCodeLengthRule(maxLength: 3600),
                LenientDisclosureMilestoneWardLengthRule(maxLength: 1000),
                LenientDisclosureMilestoneRequiredLabelRule(message: "lenient disclosure milestone needs a value"),
            ]
        )
    }
}
