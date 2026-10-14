import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan tier must pass. Check returns its problems, or none.
    protocol AcuityPlanTierRule {
        func check(_ item: AcuityPlanTier) -> [String]
    }

    final class AcuityPlanTierRetriesRangeRule: AcuityPlanTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanTier) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanTierNameLengthRule: AcuityPlanTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanTierActiveGuardRule: AcuityPlanTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AcuityPlanTier) -> [String] {
            if item.active && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class AcuityPlanTierCountryLengthRule: AcuityPlanTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanTier) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanTierVersionRangeRule: AcuityPlanTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanTier) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a acuity plan tier.
    final class AcuityPlanTierValidator {
        var rules: [any AcuityPlanTierRule]

        init(rules: [any AcuityPlanTierRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanTier]) -> [String: [String]] {
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

    static func defaultAcuityPlanTierValidator() -> AcuityPlanTierValidator {
        return AcuityPlanTierValidator(
            rules: [
                AcuityPlanTierRetriesRangeRule(min: 64, max: 3600),
                AcuityPlanTierNameLengthRule(maxLength: 86400),
                AcuityPlanTierActiveGuardRule(limit: 32),
                AcuityPlanTierCountryLengthRule(maxLength: 255),
                AcuityPlanTierVersionRangeRule(min: 64, max: 255),
            ]
        )
    }
}
