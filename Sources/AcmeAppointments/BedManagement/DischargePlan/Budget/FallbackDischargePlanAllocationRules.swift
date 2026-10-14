import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback discharge plan allocation must pass. Check returns its problems, or none.
    protocol FallbackDischargePlanAllocationRule {
        func check(_ item: FallbackDischargePlanAllocation) -> [String]
    }

    final class FallbackDischargePlanAllocationLabelLengthRule: FallbackDischargePlanAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDischargePlanAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDischargePlanAllocationAllowedLabelRule: FallbackDischargePlanAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDischargePlanAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class FallbackDischargePlanAllocationMinimumRangeRule: FallbackDischargePlanAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDischargePlanAllocation) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDischargePlanAllocationRequiredNotesRule: FallbackDischargePlanAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDischargePlanAllocation) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDischargePlanAllocationDiscountRangeRule: FallbackDischargePlanAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDischargePlanAllocation) -> [String] {
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

    final class FallbackDischargePlanAllocationApprovedGuardRule: FallbackDischargePlanAllocationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackDischargePlanAllocation) -> [String] {
            if item.approved && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback discharge plan allocation.
    final class FallbackDischargePlanAllocationValidator {
        var rules: [any FallbackDischargePlanAllocationRule]

        init(rules: [any FallbackDischargePlanAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDischargePlanAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDischargePlanAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDischargePlanAllocation]) -> [String: [String]] {
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

    static func defaultFallbackDischargePlanAllocationValidator() -> FallbackDischargePlanAllocationValidator {
        return FallbackDischargePlanAllocationValidator(
            rules: [
                FallbackDischargePlanAllocationLabelLengthRule(maxLength: 255),
                FallbackDischargePlanAllocationAllowedLabelRule(allowed: ["batched", "capped"]),
                FallbackDischargePlanAllocationMinimumRangeRule(min: 9.8, max: 4679.0),
                FallbackDischargePlanAllocationRequiredNotesRule(
                    message: "fallback discharge plan allocation needs an entry"
                ),
                FallbackDischargePlanAllocationDiscountRangeRule(min: 7.4, max: 2427.1),
                FallbackDischargePlanAllocationApprovedGuardRule(limit: 1.8),
            ]
        )
    }
}
