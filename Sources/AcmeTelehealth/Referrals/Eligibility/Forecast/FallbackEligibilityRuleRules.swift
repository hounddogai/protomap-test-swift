import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility rule must pass. Check returns its problems, or none.
    protocol FallbackEligibilityRuleRule {
        func check(_ item: FallbackEligibilityRule) -> [String]
    }

    final class FallbackEligibilityRuleRequiredCodeRule: FallbackEligibilityRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityRuleCodeLengthRule: FallbackEligibilityRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackEligibilityRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackEligibilityRuleVersionRangeRule: FallbackEligibilityRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackEligibilityRule) -> [String] {
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

    final class FallbackEligibilityRuleScoreRangeRule: FallbackEligibilityRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackEligibilityRule) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackEligibilityRuleRequiredClinicianIDRule: FallbackEligibilityRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityRule) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityRuleOwnerIDLengthRule: FallbackEligibilityRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackEligibilityRule) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility rule.
    final class FallbackEligibilityRuleValidator {
        var rules: [any FallbackEligibilityRuleRule]

        init(rules: [any FallbackEligibilityRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityRule) -> [String] {
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

        func requireValid(_ item: FallbackEligibilityRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityRule]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityRuleValidator() -> FallbackEligibilityRuleValidator {
        return FallbackEligibilityRuleValidator(
            rules: [
                FallbackEligibilityRuleRequiredCodeRule(message: "fallback eligibility rule needs an entry"),
                FallbackEligibilityRuleCodeLengthRule(maxLength: 86400),
                FallbackEligibilityRuleVersionRangeRule(min: 16, max: 80),
                FallbackEligibilityRuleScoreRangeRule(min: 2.6, max: 3266.9),
                FallbackEligibilityRuleRequiredClinicianIDRule(message: "fallback eligibility rule needs this field"),
                FallbackEligibilityRuleOwnerIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
