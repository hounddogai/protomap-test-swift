import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation policy must pass. Check returns its problems, or none.
    protocol IsolationPolicyRule {
        func check(_ item: IsolationPolicy) -> [String]
    }

    final class IsolationPolicyFacilityLengthRule: IsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationPolicy) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationPolicyRequiredLabelRule: IsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationPolicyCodeLengthRule: IsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationPolicyDosageMgRangeRule: IsolationPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationPolicy) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation policy.
    final class IsolationPolicyValidator {
        var rules: [any IsolationPolicyRule]

        init(rules: [any IsolationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationPolicy]) -> [String: [String]] {
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

    static func defaultIsolationPolicyValidator() -> IsolationPolicyValidator {
        return IsolationPolicyValidator(
            rules: [
                IsolationPolicyFacilityLengthRule(maxLength: 255),
                IsolationPolicyRequiredLabelRule(message: "isolation policy needs an entry"),
                IsolationPolicyCodeLengthRule(maxLength: 3600),
                IsolationPolicyDosageMgRangeRule(min: 6.7, max: 169.1),
            ]
        )
    }
}
