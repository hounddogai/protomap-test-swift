import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional denial claim must pass. Check returns its problems, or none.
    protocol RegionalDenialClaimRule {
        func check(_ item: RegionalDenialClaim) -> [String]
    }

    final class RegionalDenialClaimMinimumRangeRule: RegionalDenialClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDenialClaim) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalDenialClaimCodeLengthRule: RegionalDenialClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDenialClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDenialClaimRequiredTitleRule: RegionalDenialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDenialClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDenialClaimScoreRangeRule: RegionalDenialClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDenialClaim) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalDenialClaimRequiredFacilityRule: RegionalDenialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDenialClaim) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional denial claim.
    final class RegionalDenialClaimValidator {
        var rules: [any RegionalDenialClaimRule]

        init(rules: [any RegionalDenialClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDenialClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalDenialClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDenialClaim]) -> [String: [String]] {
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

    static func defaultRegionalDenialClaimValidator() -> RegionalDenialClaimValidator {
        return RegionalDenialClaimValidator(
            rules: [
                RegionalDenialClaimMinimumRangeRule(min: 3.9, max: 4523.5),
                RegionalDenialClaimCodeLengthRule(maxLength: 1000),
                RegionalDenialClaimRequiredTitleRule(message: "regional denial claim needs this field"),
                RegionalDenialClaimScoreRangeRule(min: 1.8, max: 4963.2),
                RegionalDenialClaimRequiredFacilityRule(message: "regional denial claim needs an entry"),
            ]
        )
    }
}
