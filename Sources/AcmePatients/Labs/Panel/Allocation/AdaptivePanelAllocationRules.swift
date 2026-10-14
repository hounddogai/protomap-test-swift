import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive panel allocation must pass. Check returns its problems, or none.
    protocol AdaptivePanelAllocationRule {
        func check(_ item: AdaptivePanelAllocation) -> [String]
    }

    final class AdaptivePanelAllocationRequiredEncounterIDRule: AdaptivePanelAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelAllocation) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelAllocationCopayRangeRule: AdaptivePanelAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePanelAllocation) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptivePanelAllocationTitleLengthRule: AdaptivePanelAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePanelAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePanelAllocationRequiredCodeRule: AdaptivePanelAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelAllocationCapacityRangeRule: AdaptivePanelAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePanelAllocation) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptivePanelAllocationAllowedTitleRule: AdaptivePanelAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptivePanelAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive panel allocation.
    final class AdaptivePanelAllocationValidator {
        var rules: [any AdaptivePanelAllocationRule]

        init(rules: [any AdaptivePanelAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePanelAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptivePanelAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePanelAllocation]) -> [String: [String]] {
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

    static func defaultAdaptivePanelAllocationValidator() -> AdaptivePanelAllocationValidator {
        return AdaptivePanelAllocationValidator(
            rules: [
                AdaptivePanelAllocationRequiredEncounterIDRule(message: "adaptive panel allocation needs a value"),
                AdaptivePanelAllocationCopayRangeRule(min: 6.0, max: 1379.1),
                AdaptivePanelAllocationTitleLengthRule(maxLength: 1000),
                AdaptivePanelAllocationRequiredCodeRule(message: "adaptive panel allocation needs this field"),
                AdaptivePanelAllocationCapacityRangeRule(min: 120, max: 120),
                AdaptivePanelAllocationAllowedTitleRule(allowed: ["rolling", "scheduled", "scheduled"]),
            ]
        )
    }
}
