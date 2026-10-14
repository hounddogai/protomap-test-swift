import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment allocation must pass. Check returns its problems, or none.
    protocol AssessmentAllocationRule {
        func check(_ item: AssessmentAllocation) -> [String]
    }

    final class AssessmentAllocationMinimumRangeRule: AssessmentAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentAllocation) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentAllocationAllowedNameRule: AssessmentAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class AssessmentAllocationSummaryLengthRule: AssessmentAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentAllocation) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentAllocationRequiredSummaryRule: AssessmentAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentAllocation) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentAllocationCodePrefixRule: AssessmentAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentAllocationRequiredNameRule: AssessmentAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment allocation.
    final class AssessmentAllocationValidator {
        var rules: [any AssessmentAllocationRule]

        init(rules: [any AssessmentAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentAllocation]) -> [String: [String]] {
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

    static func defaultAssessmentAllocationValidator() -> AssessmentAllocationValidator {
        return AssessmentAllocationValidator(
            rules: [
                AssessmentAllocationMinimumRangeRule(min: 3.3, max: 3901.7),
                AssessmentAllocationAllowedNameRule(allowed: ["batched", "batched", "manual"]),
                AssessmentAllocationSummaryLengthRule(maxLength: 255),
                AssessmentAllocationRequiredSummaryRule(message: "assessment allocation needs this field"),
                AssessmentAllocationCodePrefixRule(prefix: "X"),
                AssessmentAllocationRequiredNameRule(message: "assessment allocation needs an entry"),
            ]
        )
    }
}
