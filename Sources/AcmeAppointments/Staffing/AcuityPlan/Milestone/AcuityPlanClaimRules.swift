import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan claim must pass. Check returns its problems, or none.
    protocol AcuityPlanClaimRule {
        func check(_ item: AcuityPlanClaim) -> [String]
    }

    final class AcuityPlanClaimRequiredNameRule: AcuityPlanClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanClaimRequiredPayerRule: AcuityPlanClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanClaim) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanClaimPayerLengthRule: AcuityPlanClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanClaim) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanClaimWeightRangeRule: AcuityPlanClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanClaim) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a acuity plan claim.
    final class AcuityPlanClaimValidator {
        var rules: [any AcuityPlanClaimRule]

        init(rules: [any AcuityPlanClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanClaim) -> [String] {
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

        func requireValid(_ item: AcuityPlanClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanClaim]) -> [String: [String]] {
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

    static func defaultAcuityPlanClaimValidator() -> AcuityPlanClaimValidator {
        return AcuityPlanClaimValidator(
            rules: [
                AcuityPlanClaimRequiredNameRule(message: "acuity plan claim needs this field"),
                AcuityPlanClaimRequiredPayerRule(message: "acuity plan claim needs an entry"),
                AcuityPlanClaimPayerLengthRule(maxLength: 120),
                AcuityPlanClaimWeightRangeRule(min: 0.9, max: 442.0),
            ]
        )
    }
}
