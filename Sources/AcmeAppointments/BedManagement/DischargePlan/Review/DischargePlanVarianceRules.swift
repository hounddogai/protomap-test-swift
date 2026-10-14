import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan variance must pass. Check returns its problems, or none.
    protocol DischargePlanVarianceRule {
        func check(_ item: DischargePlanVariance) -> [String]
    }

    final class DischargePlanVarianceContactEmailLengthRule: DischargePlanVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanVariance) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanVarianceRequiredContactEmailRule: DischargePlanVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanVariance) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanVarianceCodePrefixRule: DischargePlanVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanVarianceRateRangeRule: DischargePlanVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanVariance) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a discharge plan variance.
    final class DischargePlanVarianceValidator {
        var rules: [any DischargePlanVarianceRule]

        init(rules: [any DischargePlanVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanVariance) -> [String] {
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

        func requireValid(_ item: DischargePlanVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanVariance]) -> [String: [String]] {
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

    static func defaultDischargePlanVarianceValidator() -> DischargePlanVarianceValidator {
        return DischargePlanVarianceValidator(
            rules: [
                DischargePlanVarianceContactEmailLengthRule(maxLength: 120),
                DischargePlanVarianceRequiredContactEmailRule(message: "discharge plan variance needs an entry"),
                DischargePlanVarianceCodePrefixRule(prefix: "REF"),
                DischargePlanVarianceRateRangeRule(min: 8.8, max: 747.0),
            ]
        )
    }
}
