import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning policy must pass. Check returns its problems, or none.
    protocol CleaningPolicyRule {
        func check(_ item: CleaningPolicy) -> [String]
    }

    final class CleaningPolicyAllowedPhoneRule: CleaningPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is below minimum"]
            }
            return []
        }
    }

    final class CleaningPolicyRatioRangeRule: CleaningPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningPolicy) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningPolicyRequiredCodeRule: CleaningPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning policy.
    final class CleaningPolicyValidator {
        var rules: [any CleaningPolicyRule]

        init(rules: [any CleaningPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningPolicy]) -> [String: [String]] {
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

    static func defaultCleaningPolicyValidator() -> CleaningPolicyValidator {
        return CleaningPolicyValidator(
            rules: [
                CleaningPolicyAllowedPhoneRule(allowed: []),
                CleaningPolicyRatioRangeRule(min: 7.3, max: 1365.3),
                CleaningPolicyRequiredCodeRule(message: "cleaning policy needs an entry"),
            ]
        )
    }
}
