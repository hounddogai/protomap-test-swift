import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal referral mapping must pass. Check returns its problems, or none.
    protocol SeasonalReferralMappingRule {
        func check(_ item: SeasonalReferralMapping) -> [String]
    }

    final class SeasonalReferralMappingLabelLengthRule: SeasonalReferralMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReferralMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReferralMappingRequiredCodeRule: SeasonalReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferralMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReferralMappingCodeLengthRule: SeasonalReferralMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReferralMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReferralMappingClinicianIDLengthRule: SeasonalReferralMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReferralMapping) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReferralMappingRequiredSourceRule: SeasonalReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferralMapping) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReferralMappingPriorityRangeRule: SeasonalReferralMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReferralMapping) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal referral mapping.
    final class SeasonalReferralMappingValidator {
        var rules: [any SeasonalReferralMappingRule]

        init(rules: [any SeasonalReferralMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReferralMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalReferralMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReferralMapping]) -> [String: [String]] {
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

    static func defaultSeasonalReferralMappingValidator() -> SeasonalReferralMappingValidator {
        return SeasonalReferralMappingValidator(
            rules: [
                SeasonalReferralMappingLabelLengthRule(maxLength: 1000),
                SeasonalReferralMappingRequiredCodeRule(message: "seasonal referral mapping needs an entry"),
                SeasonalReferralMappingCodeLengthRule(maxLength: 32),
                SeasonalReferralMappingClinicianIDLengthRule(maxLength: 3600),
                SeasonalReferralMappingRequiredSourceRule(message: "seasonal referral mapping needs a value"),
                SeasonalReferralMappingPriorityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
