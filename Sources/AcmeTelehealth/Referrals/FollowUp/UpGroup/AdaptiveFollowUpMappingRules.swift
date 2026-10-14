import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive follow up mapping must pass. Check returns its problems, or none.
    protocol AdaptiveFollowUpMappingRule {
        func check(_ item: AdaptiveFollowUpMapping) -> [String]
    }

    final class AdaptiveFollowUpMappingRefillsRangeRule: AdaptiveFollowUpMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpMapping) -> [String] {
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

    final class AdaptiveFollowUpMappingAllowedCodeRule: AdaptiveFollowUpMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveFollowUpMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class AdaptiveFollowUpMappingCapacityRangeRule: AdaptiveFollowUpMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpMapping) -> [String] {
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

    /// Runs every rule of a adaptive follow up mapping.
    final class AdaptiveFollowUpMappingValidator {
        var rules: [any AdaptiveFollowUpMappingRule]

        init(rules: [any AdaptiveFollowUpMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFollowUpMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFollowUpMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFollowUpMapping]) -> [String: [String]] {
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

    static func defaultAdaptiveFollowUpMappingValidator() -> AdaptiveFollowUpMappingValidator {
        return AdaptiveFollowUpMappingValidator(
            rules: [
                AdaptiveFollowUpMappingRefillsRangeRule(min: 32, max: 64),
                AdaptiveFollowUpMappingAllowedCodeRule(allowed: ["manual", "default", "adaptive"]),
                AdaptiveFollowUpMappingCapacityRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
