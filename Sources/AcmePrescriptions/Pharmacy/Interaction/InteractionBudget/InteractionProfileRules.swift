import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction profile must pass. Check returns its problems, or none.
    protocol InteractionProfileRule {
        func check(_ item: InteractionProfile) -> [String]
    }

    final class InteractionProfileWeightRangeRule: InteractionProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionProfile) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionProfilePriorityRangeRule: InteractionProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionProfile) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionProfileCodePrefixRule: InteractionProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionProfileRequiredSpecialtyRule: InteractionProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionProfile) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction profile.
    final class InteractionProfileValidator {
        var rules: [any InteractionProfileRule]

        init(rules: [any InteractionProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionProfile) -> [String] {
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

        func requireValid(_ item: InteractionProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionProfile]) -> [String: [String]] {
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

    static func defaultInteractionProfileValidator() -> InteractionProfileValidator {
        return InteractionProfileValidator(
            rules: [
                InteractionProfileWeightRangeRule(min: 2.4, max: 1503.2),
                InteractionProfilePriorityRangeRule(min: 32, max: 255),
                InteractionProfileCodePrefixRule(prefix: "ACM"),
                InteractionProfileRequiredSpecialtyRule(message: "interaction profile needs this field"),
            ]
        )
    }
}
