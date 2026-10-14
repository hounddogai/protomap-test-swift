import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled isolation policy must pass. Check returns its problems, or none.
    protocol ScheduledIsolationPolicyRule {
        func check(_ item: ScheduledIsolationPolicy) -> [String]
    }

    final class ScheduledIsolationPolicyExpiresAtRangeRule: ScheduledIsolationPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledIsolationPolicy) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledIsolationPolicyAllergyLengthRule: ScheduledIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledIsolationPolicy) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledIsolationPolicyCodeLengthRule: ScheduledIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledIsolationPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledIsolationPolicyDiagnosisCodeLengthRule: ScheduledIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledIsolationPolicy) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledIsolationPolicyNameLengthRule: ScheduledIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledIsolationPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled isolation policy.
    final class ScheduledIsolationPolicyValidator {
        var rules: [any ScheduledIsolationPolicyRule]

        init(rules: [any ScheduledIsolationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledIsolationPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledIsolationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledIsolationPolicy]) -> [String: [String]] {
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

    static func defaultScheduledIsolationPolicyValidator() -> ScheduledIsolationPolicyValidator {
        return ScheduledIsolationPolicyValidator(
            rules: [
                ScheduledIsolationPolicyExpiresAtRangeRule(min: 32, max: 80),
                ScheduledIsolationPolicyAllergyLengthRule(maxLength: 120),
                ScheduledIsolationPolicyCodeLengthRule(maxLength: 1000),
                ScheduledIsolationPolicyDiagnosisCodeLengthRule(maxLength: 1000),
                ScheduledIsolationPolicyNameLengthRule(maxLength: 120),
            ]
        )
    }
}
