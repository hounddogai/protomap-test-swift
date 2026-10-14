import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped formulary milestone must pass. Check returns its problems, or none.
    protocol CappedFormularyMilestoneRule {
        func check(_ item: CappedFormularyMilestone) -> [String]
    }

    final class CappedFormularyMilestoneAllowedTitleRule: CappedFormularyMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedFormularyMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class CappedFormularyMilestoneRefillsRangeRule: CappedFormularyMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFormularyMilestone) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedFormularyMilestoneCapacityRangeRule: CappedFormularyMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFormularyMilestone) -> [String] {
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

    final class CappedFormularyMilestoneRequiredCodeRule: CappedFormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFormularyMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFormularyMilestoneRequiredTitleRule: CappedFormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFormularyMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFormularyMilestoneEndsAtRangeRule: CappedFormularyMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFormularyMilestone) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped formulary milestone.
    final class CappedFormularyMilestoneValidator {
        var rules: [any CappedFormularyMilestoneRule]

        init(rules: [any CappedFormularyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFormularyMilestone) -> [String] {
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

        func requireValid(_ item: CappedFormularyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFormularyMilestone]) -> [String: [String]] {
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

    static func defaultCappedFormularyMilestoneValidator() -> CappedFormularyMilestoneValidator {
        return CappedFormularyMilestoneValidator(
            rules: [
                CappedFormularyMilestoneAllowedTitleRule(allowed: ["tiered"]),
                CappedFormularyMilestoneRefillsRangeRule(min: 16, max: 16),
                CappedFormularyMilestoneCapacityRangeRule(min: 1000, max: 3600),
                CappedFormularyMilestoneRequiredCodeRule(message: "capped formulary milestone needs an entry"),
                CappedFormularyMilestoneRequiredTitleRule(message: "capped formulary milestone needs this field"),
                CappedFormularyMilestoneEndsAtRangeRule(min: 16, max: 80),
            ]
        )
    }
}
