import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive acuity plan claim must pass. Check returns its problems, or none.
    protocol AdaptiveAcuityPlanClaimRule {
        func check(_ item: AdaptiveAcuityPlanClaim) -> [String]
    }

    final class AdaptiveAcuityPlanClaimGraceDaysRangeRule: AdaptiveAcuityPlanClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAcuityPlanClaim) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveAcuityPlanClaimCodeLengthRule: AdaptiveAcuityPlanClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAcuityPlanClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanClaimStartsAtRangeRule: AdaptiveAcuityPlanClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAcuityPlanClaim) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive acuity plan claim.
    final class AdaptiveAcuityPlanClaimValidator {
        var rules: [any AdaptiveAcuityPlanClaimRule]

        init(rules: [any AdaptiveAcuityPlanClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAcuityPlanClaim) -> [String] {
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

        func requireValid(_ item: AdaptiveAcuityPlanClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAcuityPlanClaim]) -> [String: [String]] {
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

    static func defaultAdaptiveAcuityPlanClaimValidator() -> AdaptiveAcuityPlanClaimValidator {
        return AdaptiveAcuityPlanClaimValidator(
            rules: [
                AdaptiveAcuityPlanClaimGraceDaysRangeRule(min: 64, max: 1000),
                AdaptiveAcuityPlanClaimCodeLengthRule(maxLength: 120),
                AdaptiveAcuityPlanClaimStartsAtRangeRule(min: 16, max: 120),
            ]
        )
    }
}
