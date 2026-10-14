import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling claim estimate must pass. Check returns its problems, or none.
    protocol RollingClaimEstimateRule {
        func check(_ item: RollingClaimEstimate) -> [String]
    }

    final class RollingClaimEstimateRetriesRangeRule: RollingClaimEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClaimEstimate) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingClaimEstimateCopayRangeRule: RollingClaimEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClaimEstimate) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingClaimEstimateRequiredClinicianIDRule: RollingClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimEstimate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling claim estimate.
    final class RollingClaimEstimateValidator {
        var rules: [any RollingClaimEstimateRule]

        init(rules: [any RollingClaimEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClaimEstimate) -> [String] {
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

        func requireValid(_ item: RollingClaimEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClaimEstimate]) -> [String: [String]] {
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

    static func defaultRollingClaimEstimateValidator() -> RollingClaimEstimateValidator {
        return RollingClaimEstimateValidator(
            rules: [
                RollingClaimEstimateRetriesRangeRule(min: 16, max: 80),
                RollingClaimEstimateCopayRangeRule(min: 1.0, max: 1558.3),
                RollingClaimEstimateRequiredClinicianIDRule(message: "rolling claim estimate needs this field"),
            ]
        )
    }
}
