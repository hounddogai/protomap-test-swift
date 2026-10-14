import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap claim must pass. Check returns its problems, or none.
    protocol CareGapClaimRule {
        func check(_ item: CareGapClaim) -> [String]
    }

    final class CareGapClaimRequiredFacilityRule: CareGapClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapClaim) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapClaimAllowedFacilityRule: CareGapClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is inconsistent"]
            }
            return []
        }
    }

    final class CareGapClaimCeilingRangeRule: CareGapClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapClaim) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap claim.
    final class CareGapClaimValidator {
        var rules: [any CareGapClaimRule]

        init(rules: [any CareGapClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapClaim) -> [String] {
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

        func requireValid(_ item: CareGapClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapClaim]) -> [String: [String]] {
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

    static func defaultCareGapClaimValidator() -> CareGapClaimValidator {
        return CareGapClaimValidator(
            rules: [
                CareGapClaimRequiredFacilityRule(message: "care gap claim needs an entry"),
                CareGapClaimAllowedFacilityRule(allowed: ["global", "weighted"]),
                CareGapClaimCeilingRangeRule(min: 9.3, max: 2234.3),
            ]
        )
    }
}
