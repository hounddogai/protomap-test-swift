import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance threshold must pass. Check returns its problems, or none.
    protocol RemittanceThresholdRule {
        func check(_ item: RemittanceThreshold) -> [String]
    }

    final class RemittanceThresholdDiscountRangeRule: RemittanceThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceThreshold) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceThresholdRequiredTimezoneRule: RemittanceThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceThreshold) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceThresholdDescriptionLengthRule: RemittanceThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceThreshold) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance threshold.
    final class RemittanceThresholdValidator {
        var rules: [any RemittanceThresholdRule]

        init(rules: [any RemittanceThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceThreshold) -> [String] {
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

        func requireValid(_ item: RemittanceThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceThreshold]) -> [String: [String]] {
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

    static func defaultRemittanceThresholdValidator() -> RemittanceThresholdValidator {
        return RemittanceThresholdValidator(
            rules: [
                RemittanceThresholdDiscountRangeRule(min: 8.1, max: 855.8),
                RemittanceThresholdRequiredTimezoneRule(message: "remittance threshold needs this field"),
                RemittanceThresholdDescriptionLengthRule(maxLength: 120),
            ]
        )
    }
}
