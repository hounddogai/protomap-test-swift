import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal care protocol policy must pass. Check returns its problems, or none.
    protocol SeasonalCareProtocolPolicyRule {
        func check(_ item: SeasonalCareProtocolPolicy) -> [String]
    }

    final class SeasonalCareProtocolPolicyRequiredNameRule: SeasonalCareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareProtocolPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareProtocolPolicyFacilityLengthRule: SeasonalCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareProtocolPolicy) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolPolicyCodeLengthRule: SeasonalCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareProtocolPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolPolicyRequiredCodeRule: SeasonalCareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareProtocolPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareProtocolPolicyWindowDaysRangeRule: SeasonalCareProtocolPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareProtocolPolicy) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolPolicyNameLengthRule: SeasonalCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareProtocolPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care protocol policy.
    final class SeasonalCareProtocolPolicyValidator {
        var rules: [any SeasonalCareProtocolPolicyRule]

        init(rules: [any SeasonalCareProtocolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareProtocolPolicy) -> [String] {
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

        func requireValid(_ item: SeasonalCareProtocolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareProtocolPolicy]) -> [String: [String]] {
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

    static func defaultSeasonalCareProtocolPolicyValidator() -> SeasonalCareProtocolPolicyValidator {
        return SeasonalCareProtocolPolicyValidator(
            rules: [
                SeasonalCareProtocolPolicyRequiredNameRule(message: "seasonal care protocol policy needs a value"),
                SeasonalCareProtocolPolicyFacilityLengthRule(maxLength: 80),
                SeasonalCareProtocolPolicyCodeLengthRule(maxLength: 64),
                SeasonalCareProtocolPolicyRequiredCodeRule(message: "seasonal care protocol policy needs a value"),
                SeasonalCareProtocolPolicyWindowDaysRangeRule(min: 16, max: 1000),
                SeasonalCareProtocolPolicyNameLengthRule(maxLength: 64),
            ]
        )
    }
}
