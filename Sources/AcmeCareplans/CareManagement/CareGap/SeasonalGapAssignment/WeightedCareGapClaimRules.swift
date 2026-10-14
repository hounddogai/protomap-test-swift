import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted care gap claim must pass. Check returns its problems, or none.
    protocol WeightedCareGapClaimRule {
        func check(_ item: WeightedCareGapClaim) -> [String]
    }

    final class WeightedCareGapClaimGraceDaysRangeRule: WeightedCareGapClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareGapClaim) -> [String] {
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

    final class WeightedCareGapClaimRequiredRegionRule: WeightedCareGapClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCareGapClaim) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCareGapClaimWindowDaysRangeRule: WeightedCareGapClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareGapClaim) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCareGapClaimAllowedCodeRule: WeightedCareGapClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedCareGapClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class WeightedCareGapClaimUnitLengthRule: WeightedCareGapClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareGapClaim) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCareGapClaimExpiresAtRangeRule: WeightedCareGapClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareGapClaim) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted care gap claim.
    final class WeightedCareGapClaimValidator {
        var rules: [any WeightedCareGapClaimRule]

        init(rules: [any WeightedCareGapClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCareGapClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCareGapClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCareGapClaim]) -> [String: [String]] {
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

    static func defaultWeightedCareGapClaimValidator() -> WeightedCareGapClaimValidator {
        return WeightedCareGapClaimValidator(
            rules: [
                WeightedCareGapClaimGraceDaysRangeRule(min: 120, max: 1000),
                WeightedCareGapClaimRequiredRegionRule(message: "weighted care gap claim needs this field"),
                WeightedCareGapClaimWindowDaysRangeRule(min: 120, max: 3600),
                WeightedCareGapClaimAllowedCodeRule(allowed: ["tiered"]),
                WeightedCareGapClaimUnitLengthRule(maxLength: 32),
                WeightedCareGapClaimExpiresAtRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
