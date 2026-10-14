import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach policy must pass. Check returns its problems, or none.
    protocol OutreachPolicyRule {
        func check(_ item: OutreachPolicy) -> [String]
    }

    final class OutreachPolicyRequiredLabelRule: OutreachPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachPolicyRefillsRangeRule: OutreachPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachPolicy) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachPolicyCodePrefixRule: OutreachPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachPolicyWindowDaysRangeRule: OutreachPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachPolicy) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachPolicyAllowedRegionRule: OutreachPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is inconsistent"]
            }
            return []
        }
    }

    final class OutreachPolicyRequiredRegionRule: OutreachPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachPolicy) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach policy.
    final class OutreachPolicyValidator {
        var rules: [any OutreachPolicyRule]

        init(rules: [any OutreachPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachPolicy]) -> [String: [String]] {
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

    static func defaultOutreachPolicyValidator() -> OutreachPolicyValidator {
        return OutreachPolicyValidator(
            rules: [
                OutreachPolicyRequiredLabelRule(message: "outreach policy needs a value"),
                OutreachPolicyRefillsRangeRule(min: 80, max: 1000),
                OutreachPolicyCodePrefixRule(prefix: "X"),
                OutreachPolicyWindowDaysRangeRule(min: 120, max: 3600),
                OutreachPolicyAllowedRegionRule(allowed: ["default", "weighted"]),
                OutreachPolicyRequiredRegionRule(message: "outreach policy needs a value"),
            ]
        )
    }
}
