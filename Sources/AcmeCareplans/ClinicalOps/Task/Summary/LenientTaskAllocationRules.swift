import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient task allocation must pass. Check returns its problems, or none.
    protocol LenientTaskAllocationRule {
        func check(_ item: LenientTaskAllocation) -> [String]
    }

    final class LenientTaskAllocationWeightRangeRule: LenientTaskAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientTaskAllocation) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientTaskAllocationRequiredCodeRule: LenientTaskAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTaskAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTaskAllocationCodeLengthRule: LenientTaskAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientTaskAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientTaskAllocationAllowedAllergyRule: LenientTaskAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientTaskAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient task allocation.
    final class LenientTaskAllocationValidator {
        var rules: [any LenientTaskAllocationRule]

        init(rules: [any LenientTaskAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientTaskAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientTaskAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientTaskAllocation]) -> [String: [String]] {
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

    static func defaultLenientTaskAllocationValidator() -> LenientTaskAllocationValidator {
        return LenientTaskAllocationValidator(
            rules: [
                LenientTaskAllocationWeightRangeRule(min: 0.3, max: 1444.4),
                LenientTaskAllocationRequiredCodeRule(message: "lenient task allocation needs this field"),
                LenientTaskAllocationCodeLengthRule(maxLength: 1000),
                LenientTaskAllocationAllowedAllergyRule(allowed: ["scheduled", "pending"]),
            ]
        )
    }
}
