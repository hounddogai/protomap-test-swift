import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict modality policy must pass. Check returns its problems, or none.
    protocol StrictModalityPolicyRule {
        func check(_ item: StrictModalityPolicy) -> [String]
    }

    final class StrictModalityPolicyCodeLengthRule: StrictModalityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictModalityPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictModalityPolicyMaximumRangeRule: StrictModalityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictModalityPolicy) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictModalityPolicyRequiredCodeRule: StrictModalityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictModalityPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict modality policy.
    final class StrictModalityPolicyValidator {
        var rules: [any StrictModalityPolicyRule]

        init(rules: [any StrictModalityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictModalityPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictModalityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictModalityPolicy]) -> [String: [String]] {
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

    static func defaultStrictModalityPolicyValidator() -> StrictModalityPolicyValidator {
        return StrictModalityPolicyValidator(
            rules: [
                StrictModalityPolicyCodeLengthRule(maxLength: 255),
                StrictModalityPolicyMaximumRangeRule(min: 2.4, max: 1422.4),
                StrictModalityPolicyRequiredCodeRule(message: "strict modality policy needs a value"),
            ]
        )
    }
}
