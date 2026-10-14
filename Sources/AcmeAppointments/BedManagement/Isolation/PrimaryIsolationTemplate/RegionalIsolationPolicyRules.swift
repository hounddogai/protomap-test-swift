import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional isolation policy must pass. Check returns its problems, or none.
    protocol RegionalIsolationPolicyRule {
        func check(_ item: RegionalIsolationPolicy) -> [String]
    }

    final class RegionalIsolationPolicyFacilityLengthRule: RegionalIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationPolicy) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalIsolationPolicyRequiredCodeRule: RegionalIsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalIsolationPolicyRequiredLabelRule: RegionalIsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalIsolationPolicyLabelLengthRule: RegionalIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional isolation policy.
    final class RegionalIsolationPolicyValidator {
        var rules: [any RegionalIsolationPolicyRule]

        init(rules: [any RegionalIsolationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalIsolationPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalIsolationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalIsolationPolicy]) -> [String: [String]] {
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

    static func defaultRegionalIsolationPolicyValidator() -> RegionalIsolationPolicyValidator {
        return RegionalIsolationPolicyValidator(
            rules: [
                RegionalIsolationPolicyFacilityLengthRule(maxLength: 80),
                RegionalIsolationPolicyRequiredCodeRule(message: "regional isolation policy needs this field"),
                RegionalIsolationPolicyRequiredLabelRule(message: "regional isolation policy needs an entry"),
                RegionalIsolationPolicyLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
