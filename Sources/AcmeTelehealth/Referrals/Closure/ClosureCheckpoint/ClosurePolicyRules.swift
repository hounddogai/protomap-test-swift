import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure policy must pass. Check returns its problems, or none.
    protocol ClosurePolicyRule {
        func check(_ item: ClosurePolicy) -> [String]
    }

    final class ClosurePolicyRequiredLabelRule: ClosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosurePolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosurePolicyFloorValueRangeRule: ClosurePolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosurePolicy) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosurePolicyAllowedCodeRule: ClosurePolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosurePolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ClosurePolicyRequiredNameRule: ClosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosurePolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosurePolicyRequiredNotesRule: ClosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosurePolicy) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosurePolicyRequiredCodeRule: ClosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosurePolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure policy.
    final class ClosurePolicyValidator {
        var rules: [any ClosurePolicyRule]

        init(rules: [any ClosurePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosurePolicy) -> [String] {
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

        func requireValid(_ item: ClosurePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosurePolicy]) -> [String: [String]] {
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

    static func defaultClosurePolicyValidator() -> ClosurePolicyValidator {
        return ClosurePolicyValidator(
            rules: [
                ClosurePolicyRequiredLabelRule(message: "closure policy needs this field"),
                ClosurePolicyFloorValueRangeRule(min: 7.5, max: 2557.2),
                ClosurePolicyAllowedCodeRule(allowed: ["lenient", "lenient"]),
                ClosurePolicyRequiredNameRule(message: "closure policy needs a value"),
                ClosurePolicyRequiredNotesRule(message: "closure policy needs a value"),
                ClosurePolicyRequiredCodeRule(message: "closure policy needs this field"),
            ]
        )
    }
}
