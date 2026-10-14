import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial variance must pass. Check returns its problems, or none.
    protocol DenialVarianceRule {
        func check(_ item: DenialVariance) -> [String]
    }

    final class DenialVarianceDosageMgRangeRule: DenialVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialVariance) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialVarianceRequiredFacilityRule: DenialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialVariance) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialVarianceFacilityLengthRule: DenialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialVariance) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialVarianceRequiredCodeRule: DenialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial variance.
    final class DenialVarianceValidator {
        var rules: [any DenialVarianceRule]

        init(rules: [any DenialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialVariance]) -> [String: [String]] {
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

    static func defaultDenialVarianceValidator() -> DenialVarianceValidator {
        return DenialVarianceValidator(
            rules: [
                DenialVarianceDosageMgRangeRule(min: 0.3, max: 786.0),
                DenialVarianceRequiredFacilityRule(message: "denial variance needs an entry"),
                DenialVarianceFacilityLengthRule(maxLength: 16),
                DenialVarianceRequiredCodeRule(message: "denial variance needs this field"),
            ]
        )
    }
}
